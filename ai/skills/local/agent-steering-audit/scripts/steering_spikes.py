#!/usr/bin/env python3
"""Temporary steering-analysis spikes for long-running Codex sessions.

This streams the Codex JSONL log and emits compact derived summaries. It is not
repo infrastructure.
"""

from __future__ import annotations

import argparse
import json
import math
import re
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


ANSI_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")

PRIMITIVES: dict[str, re.Pattern[str]] = {
    "abd": re.compile(r"\bABD\b|always be dispatching", re.I),
    "ri_owner": re.compile(r"\bRI owner\b|reference implementation owner", re.I),
    "confidence_gate": re.compile(r"\bconfidence\b|95%\+?|99%\+?|100%|SLVP ideal", re.I),
    "expected_state": re.compile(r"\b(expected|expect to see|look as you expect|is this right|that's not right)\b", re.I),
    "contradiction_check": re.compile(r"\b(serially|did you actually|did you review|did you forget|not what|supposed to|why did|how did)\b", re.I),
    "closure_gate": re.compile(r"\b(do not stop|don't stop|until .*verifi|fully deliver|true closure|closeout|closure|done done)\b", re.I),
    "stop_condition_repair": re.compile(
        r"\b(why should you return|why .*return|human in the loop|not blocked|what are you waiting for|"
        r"stopping just because|returning here because|premature(?:ly)? return|keep going until)\b",
        re.I,
    ),
    "docket_state": re.compile(
        r"\b(where are we|what'?s next|next steps|what else are you tracking|what'?s the status|"
        r"list them|overall plan|remaining|active docket)\b",
        re.I,
    ),
    "durability_demand": re.compile(r"\b(write|document|capture|record|preserve).{0,80}\b(file|disk|md|report|openspec|design note|artifact)\b", re.I),
    "evidence_injection": re.compile(r"\b(log|trace|screenshot|records|dashboard|run_|error|stack|output|statusCode|stderr|stdout)\b", re.I),
    "worker_dispatch": re.compile(r"\b(worker|dispatch|claude|subagent|tmux|parallelize|parallel)\b", re.I),
    "scope_reset": re.compile(r"\b(my target|actual target|overall|single task|what's next|from here|not the point)\b", re.I),
}


def existing_file_arg(value: str) -> Path:
    if not value.strip():
        raise argparse.ArgumentTypeError("--session must not be empty")
    path = Path(value).expanduser()
    if not path.is_file():
        raise argparse.ArgumentTypeError(f"{path} is not a file")
    return path

CORRECTION_RE = re.compile(
    r"\b(no\b|not\b|wrong|incorrect|confus|forget|forgot|missed|lost|repeat|serially|why did|how did|supposed|"
    r"that's not|isn't|wasn't|shouldn't|doesn't|don't want|wall of text|too vague|slop|hack)\b",
    re.I,
)

POSITIVE_CONTINUATION_RE = re.compile(
    r"\b(proceed|continue|excellent|great|good find|thank you|what'?s next|keep going|let'?s|get it done)\b",
    re.I,
)

RESOLUTION_RE = re.compile(
    r"\b(complete|completed|landed|merged|pushed|closed|archived|validated|verified|report is in|finished|"
    r"failed|aborted|no report|still running|blocked|parked|deferred|ready for review)\b",
    re.I,
)

DISPATCH_RE = re.compile(r"\b(dispatched|launch(?:ed)?|spawn(?:ed)?|worker|claude|tmux|subagent|lane)\b", re.I)

COMMIT_RE = re.compile(r"\b[0-9a-f]{7,12}\b")


def clean(text: str) -> str:
    text = ANSI_RE.sub("", text or "")
    return re.sub(r"\s+", " ", text).strip()


def parse_ts(ts: str) -> datetime | None:
    if not ts:
        return None
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except ValueError:
        return None


def week_key(ts: str) -> str:
    dt = parse_ts(ts)
    if dt is None:
        return "unknown"
    year, week, _ = dt.isocalendar()
    return f"{year}-W{week:02d}"


def hour_bucket(ts: str, hours: int) -> str:
    dt = parse_ts(ts)
    if dt is None:
        return "unknown"
    dt = dt.astimezone(timezone.utc)
    bucket_hour = (dt.hour // hours) * hours
    return dt.replace(hour=bucket_hour, minute=0, second=0, microsecond=0).isoformat().replace("+00:00", "Z")


@dataclass
class Turn:
    idx: int
    user_ts: str
    user_line: int
    user: str
    first_agent: str = ""
    final_agent: str = ""
    agent_messages: int = 0
    tool_calls: Counter[str] = field(default_factory=Counter)
    patches: int = 0
    compactions: int = 0
    custom_calls: Counter[str] = field(default_factory=Counter)

    @property
    def primitives(self) -> list[str]:
        return [name for name, pat in PRIMITIVES.items() if pat.search(self.user)]

    @property
    def is_correction(self) -> bool:
        return bool(CORRECTION_RE.search(self.user))

    @property
    def is_positive_continuation(self) -> bool:
        return bool(POSITIVE_CONTINUATION_RE.search(self.user))

    @property
    def is_dispatch_related(self) -> bool:
        hay = f"{self.user}\n{self.first_agent}\n{self.final_agent}"
        return bool(DISPATCH_RE.search(hay))

    @property
    def has_resolution(self) -> bool:
        hay = f"{self.first_agent}\n{self.final_agent}"
        return bool(RESOLUTION_RE.search(hay))

    @property
    def evidence_score(self) -> float:
        hay = f"{self.first_agent}\n{self.final_agent}"
        validation = len(re.findall(r"\b(test|typecheck|validate|verified|deployed|screenshot|timeline|log|commit|pushed|merged)\b", hay, re.I))
        commits = len(COMMIT_RE.findall(hay))
        return validation + min(commits, 5) + self.patches * 1.5 + sum(self.tool_calls.values()) / 30


def iter_turns(path: Path) -> Iterable[Turn]:
    current: Turn | None = None
    idx = 0

    def finish() -> Turn | None:
        nonlocal current
        if current is None:
            return None
        out = current
        current = None
        return out

    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line_no, line in enumerate(handle, 1):
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            typ = obj.get("type")
            payload = obj.get("payload") or {}
            ptype = payload.get("type")
            ts = obj.get("timestamp", "")

            if typ == "event_msg" and ptype == "user_message":
                pending = finish()
                if pending is not None:
                    yield pending
                msg = payload.get("message")
                if not isinstance(msg, str):
                    continue
                idx += 1
                current = Turn(idx=idx, user_ts=ts, user_line=line_no, user=clean(msg))
                continue

            if current is None:
                continue

            if typ == "event_msg" and ptype == "agent_message":
                msg = payload.get("message")
                if isinstance(msg, str) and msg.strip():
                    c = clean(msg)
                    current.agent_messages += 1
                    if not current.first_agent:
                        current.first_agent = c
                    current.final_agent = c
            elif typ == "event_msg" and ptype == "task_complete":
                msg = payload.get("last_agent_message")
                if isinstance(msg, str) and msg.strip():
                    current.final_agent = clean(msg)
            elif typ == "response_item" and ptype == "function_call":
                current.tool_calls[payload.get("name") or "?"] += 1
            elif typ == "response_item" and ptype == "custom_tool_call":
                current.custom_calls[payload.get("name") or "?"] += 1
            elif typ == "event_msg" and ptype == "patch_apply_end":
                current.patches += 1
            elif typ == "compacted":
                current.compactions += 1

    pending = finish()
    if pending is not None:
        yield pending


def snippet(text: str, limit: int = 220) -> str:
    text = clean(text)
    return text if len(text) <= limit else text[: limit - 3].rstrip() + "..."


def window_stats(turns: list[Turn], hours: int = 6) -> list[dict]:
    buckets: dict[str, list[Turn]] = defaultdict(list)
    for turn in turns:
        buckets[hour_bucket(turn.user_ts, hours)].append(turn)
    rows = []
    for bucket, items in buckets.items():
        if bucket == "unknown":
            continue
        user_count = len(items)
        corrections = sum(t.is_correction for t in items)
        repair_turns = sum(
            t.is_correction
            or bool({"stop_condition_repair", "contradiction_check", "expected_state"} & set(t.primitives))
            for t in items
        )
        positives = sum(t.is_positive_continuation for t in items)
        tools = sum(sum(t.tool_calls.values()) for t in items)
        patches = sum(t.patches for t in items)
        compactions = sum(t.compactions for t in items)
        evidence = sum(t.evidence_score for t in items)
        dispatch = sum(t.is_dispatch_related for t in items)
        # Positive velocity is intentionally heuristic; it only proposes windows.
        flying = evidence + tools / 60 + patches * 1.5 + positives * 2 - corrections * 2 - compactions * 0.5
        friction = corrections * 3 + dispatch + compactions - positives
        rows.append(
            {
                "bucket": bucket,
                "turns": user_count,
                "corrections": corrections,
                "repair_turns": repair_turns,
                "positives": positives,
                "tools": tools,
                "patches": patches,
                "compactions": compactions,
                "dispatch_turns": dispatch,
                "evidence": round(evidence, 1),
                "flying_score": round(flying, 1),
                "friction_score": round(friction, 1),
                "examples": [f"u{t.idx:06d} {t.user_ts} {snippet(t.user, 120)}" for t in items[:3]],
            }
        )
    return rows


def percentile(values: list[float], pct: float) -> float:
    if not values:
        return 0
    ordered = sorted(values)
    pos = (len(ordered) - 1) * pct
    lo = math.floor(pos)
    hi = math.ceil(pos)
    if lo == hi:
        return ordered[int(pos)]
    return ordered[lo] * (hi - pos) + ordered[hi] * (pos - lo)


def contrastive_windows(windows: list[dict]) -> dict:
    enriched = []
    for row in windows:
        turns = max(row["turns"], 1)
        corr_rate = row["corrections"] / turns
        repair_rate = row["repair_turns"] / turns
        positive_rate = row["positives"] / turns
        evidence_per_turn = row["evidence"] / turns
        dispatch_rate = row["dispatch_turns"] / turns
        enriched.append(
            {
                **row,
                "correction_rate": round(corr_rate, 3),
                "semantic_friction_rate": round(repair_rate, 3),
                "positive_rate": round(positive_rate, 3),
                "dispatch_rate": round(dispatch_rate, 3),
                "evidence_per_turn": round(evidence_per_turn, 1),
                "quiet_autonomy_score": round(evidence_per_turn + positive_rate * 10 - repair_rate * 12, 1),
            }
        )

    evidence_p70 = percentile([r["evidence"] for r in enriched], 0.70)
    evidence_per_turn_p70 = percentile([r["evidence_per_turn"] for r in enriched], 0.70)
    friction_p30 = percentile([r["semantic_friction_rate"] for r in enriched], 0.30)
    friction_p70 = percentile([r["semantic_friction_rate"] for r in enriched], 0.70)
    dispatch_p80 = percentile([r["dispatch_turns"] for r in enriched], 0.80)

    quiet = [
        r
        for r in enriched
        if r["turns"] >= 3
        and r["evidence"] >= evidence_p70
        and r["evidence_per_turn"] >= evidence_per_turn_p70
        and r["semantic_friction_rate"] <= friction_p30
    ]
    high_friction = [
        r
        for r in enriched
        if r["turns"] >= 5 and r["evidence"] >= evidence_p70 and r["semantic_friction_rate"] >= friction_p70
    ]
    coordination_pressure = [
        r
        for r in enriched
        if r["turns"] >= 10 and r["dispatch_turns"] >= dispatch_p80 and r["semantic_friction_rate"] >= friction_p70
    ]
    positive_low_correction = [
        r
        for r in enriched
        if r["positives"] >= 3 and r["corrections"] <= 1 and r["evidence"] >= evidence_p70 / 2
    ]

    return {
        "thresholds": {
            "evidence_p70": round(evidence_p70, 1),
            "evidence_per_turn_p70": round(evidence_per_turn_p70, 1),
            "semantic_friction_rate_p30": round(friction_p30, 3),
            "semantic_friction_rate_p70": round(friction_p70, 3),
            "dispatch_turns_p80": round(dispatch_p80, 1),
        },
        "quiet_high_output": sorted(quiet, key=lambda r: r["quiet_autonomy_score"], reverse=True)[:20],
        "high_output_high_friction": sorted(high_friction, key=lambda r: (r["correction_rate"], r["evidence"]), reverse=True)[:20],
        "coordination_pressure": sorted(coordination_pressure, key=lambda r: (r["dispatch_turns"], r["correction_rate"]), reverse=True)[:20],
        "positive_low_correction": sorted(positive_low_correction, key=lambda r: (r["positives"], r["evidence"]), reverse=True)[:20],
    }


def primitive_stats(turns: list[Turn]) -> dict:
    by_week: dict[str, Counter[str]] = defaultdict(Counter)
    examples: dict[str, list[str]] = defaultdict(list)
    uptake: dict[str, Counter[str]] = defaultdict(Counter)
    for turn in turns:
        primitives = turn.primitives
        for primitive in primitives:
            by_week[week_key(turn.user_ts)][primitive] += 1
            if len(examples[primitive]) < 8:
                examples[primitive].append(
                    f"u{turn.idx:06d} {turn.user_ts} line {turn.user_line}: {snippet(turn.user, 180)}"
                )
            if turn.has_resolution:
                uptake[primitive]["resolution_language"] += 1
            if turn.evidence_score >= 5:
                uptake[primitive]["evidence_bound"] += 1
            if turn.is_correction:
                uptake[primitive]["correction_context"] += 1
            uptake[primitive]["total"] += 1
    return {
        "by_week": {week: dict(counter.most_common()) for week, counter in sorted(by_week.items())},
        "examples": dict(examples),
        "uptake": {name: dict(counter) for name, counter in uptake.items()},
    }


def dispatch_resolution(turns: list[Turn], lookahead: int = 12) -> dict:
    candidates = []
    for i, turn in enumerate(turns):
        hay = f"{turn.user}\n{turn.first_agent}\n{turn.final_agent}"
        if not DISPATCH_RE.search(hay):
            continue
        future = turns[i + 1 : i + 1 + lookahead]
        resolution_hits = [t for t in future if t.has_resolution]
        correction_hits = [t for t in future if t.is_correction]
        candidates.append(
            {
                "id": f"u{turn.idx:06d}",
                "ts": turn.user_ts,
                "line": turn.user_line,
                "dispatch_text": snippet(turn.user, 200),
                "assistant_hint": snippet(turn.final_agent, 220),
                "resolution_within_lookahead": bool(resolution_hits),
                "first_resolution": (
                    f"u{resolution_hits[0].idx:06d} {resolution_hits[0].user_ts}: {snippet(resolution_hits[0].final_agent, 160)}"
                    if resolution_hits
                    else ""
                ),
                "corrections_within_lookahead": len(correction_hits),
                "next_correction": (
                    f"u{correction_hits[0].idx:06d} {correction_hits[0].user_ts}: {snippet(correction_hits[0].user, 160)}"
                    if correction_hits
                    else ""
                ),
            }
        )
    unresolved = [c for c in candidates if not c["resolution_within_lookahead"]]
    noisy = [c for c in candidates if c["corrections_within_lookahead"] >= 3]
    noisy_unresolved = sorted(unresolved, key=lambda c: c["corrections_within_lookahead"], reverse=True)
    return {
        "dispatch_candidates": len(candidates),
        "resolved_within_lookahead": sum(c["resolution_within_lookahead"] for c in candidates),
        "unresolved_within_lookahead": len(unresolved),
        "top_unresolved_or_noisy": noisy_unresolved[:20],
        "resolved_but_noisy": sorted(noisy, key=lambda c: c["corrections_within_lookahead"], reverse=True)[:30],
        "sample_resolved": [c for c in candidates if c["resolution_within_lookahead"]][:12],
    }


def dump_window(turns: list[Turn], start: str, end: str) -> str:
    start_dt = parse_ts(start)
    end_dt = parse_ts(end)
    if start_dt is None or end_dt is None:
        raise SystemExit("--dump-window timestamps must be ISO timestamps")
    selected = [t for t in turns if t.user_ts and start_dt <= parse_ts(t.user_ts) < end_dt]
    lines = [
        f"# Window Dump: {start} -> {end}",
        "",
        f"Turns: {len(selected)}",
        "",
    ]
    for turn in selected:
        flags = []
        if turn.is_correction:
            flags.append("CORR")
        if turn.is_positive_continuation:
            flags.append("POS")
        if turn.has_resolution:
            flags.append("RES")
        flags.extend(turn.primitives)
        tools = sum(turn.tool_calls.values())
        lines.extend(
            [
                f"## u{turn.idx:06d} {turn.user_ts} line {turn.user_line}",
                f"flags: {', '.join(flags) if flags else '-'}; tools={tools}; patches={turn.patches}; compactions={turn.compactions}; evidence={turn.evidence_score:.1f}",
                "",
                f"User: {snippet(turn.user, 500)}",
                "",
                f"Agent final: {snippet(turn.final_agent, 500)}",
                "",
            ]
        )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--session", required=True, type=existing_file_arg)
    parser.add_argument("--window-hours", type=int, default=6)
    parser.add_argument("--lookahead", type=int, default=12)
    parser.add_argument("--dump-window", nargs=2, metavar=("START", "END"))
    args = parser.parse_args()

    turns = list(iter_turns(args.session))
    if args.dump_window:
        print(dump_window(turns, args.dump_window[0], args.dump_window[1]))
        return

    windows = window_stats(turns, args.window_hours)
    result = {
        "session": str(args.session),
        "turns": len(turns),
        "primitive_counts": dict(Counter(p for t in turns for p in t.primitives).most_common()),
        "top_flying_windows": sorted(windows, key=lambda r: r["flying_score"], reverse=True)[:20],
        "top_friction_windows": sorted(windows, key=lambda r: r["friction_score"], reverse=True)[:20],
        "contrastive_windows": contrastive_windows(windows),
        "primitive_stats": primitive_stats(turns),
        "dispatch_resolution": dispatch_resolution(turns, args.lookahead),
    }
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
