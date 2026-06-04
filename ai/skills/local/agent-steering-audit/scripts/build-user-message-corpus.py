#!/usr/bin/env python3
"""Build a long-context review corpus from Codex JSONL user messages.

This is a temporary audit aid, not product code.
It selects only event_msg/user_message records because response_item role=user
contains duplicated and injected runtime content.
"""

from __future__ import annotations

import argparse
import html
import json
import re
from collections import Counter
from pathlib import Path


DEFAULT_OUT = Path("tmp/workstreams/agent-steering-audit-user-message-corpus.txt")
DEFAULT_STATS = Path("tmp/workstreams/agent-steering-audit-user-message-corpus.stats.json")
DEFAULT_CONTEXT_OUT = Path("tmp/workstreams/agent-steering-audit-user-agent-context-corpus.txt")
DEFAULT_CONTEXT_STATS = Path("tmp/workstreams/agent-steering-audit-user-agent-context-corpus.stats.json")

ANSI_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
SESSION_ID_RE = re.compile(
    r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.jsonl$",
    re.IGNORECASE,
)
SECRET_PATTERNS = [
    re.compile(
        r"(?i)\b(api[_-]?key|access[_-]?token|refresh[_-]?token|session[_-]?cookie|cookie|secret|password)\b"
        r"(\s*[:=]\s*)([^\s,;]+)"
    ),
    re.compile(r"(?i)\b(bearer)\s+([A-Za-z0-9._~+/=-]{16,})"),
]

TAG_PATTERNS = {
    "confidence_prompt": re.compile(r"\b(confidence|95%|99%|100%|slvp ideal)\b", re.I),
    "worker_handoff": re.compile(r"\b(worker|dispatch|subagent|claude|parallelize|parallel)\b", re.I),
    "abd_refresh_ri_owner": re.compile(r"\b(ABD|refresh\.?\s*md|RI owner|reference implementation owner)\b", re.I),
    "uat_feedback": re.compile(r"\b(i clicked|i tried|i submitted|browser|screenshot|otp|live|it shows|i see)\b", re.I),
    "scope_reset": re.compile(r"\b(overall|actual target|my target|single task|what'?s next|from here|closure)\b", re.I),
    "status_question": re.compile(r"\b(status|where are we|what are you up to|what landed|what remains|tracking)\b", re.I),
    "durable_memory": re.compile(r"\b(remember|don't forget|reread|read the refresh|always be|never forget)\b", re.I),
}


def existing_file_arg(value: str) -> Path:
    if not value.strip():
        raise argparse.ArgumentTypeError("--session must not be empty")
    path = Path(value).expanduser()
    if not path.is_file():
        raise argparse.ArgumentTypeError(f"{path} is not a file")
    return path


def strip_ansi(text: str) -> str:
    return ANSI_RE.sub("", text)


def redact(text: str) -> str:
    redacted = text
    redacted = SECRET_PATTERNS[0].sub(lambda m: f"{m.group(1)}{m.group(2)}[REDACTED]", redacted)
    redacted = SECRET_PATTERNS[1].sub(lambda m: f"{m.group(1)} [REDACTED]", redacted)
    return redacted


def cdata_safe(text: str) -> str:
    return text.replace("]]>", "]]]]><![CDATA[>")


def clip_context(text: str, limit: int) -> tuple[str, bool]:
    clean = redact(strip_ansi(text)).strip()
    if limit <= 0 or len(clean) <= limit:
        return clean, False
    return clean[:limit].rstrip() + "\n[...truncated...]", True


def session_id_from_path(path: Path) -> str:
    match = SESSION_ID_RE.search(path.name)
    return match.group(1) if match else path.stem


def tags_for(message: str) -> list[str]:
    tags: list[str] = []
    line_count = message.count("\n") + 1
    if len(message) > 3000 or line_count > 50:
        tags.append("long_pasted_report")
    stripped = message.lstrip()
    if stripped.startswith(">") or "\n>" in message or stripped.startswith('"'):
        tags.append("quote_response")
    for tag, pattern in TAG_PATTERNS.items():
        if pattern.search(message):
            tags.append(tag)
    return tags


def iter_user_messages(path: Path):
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line_no, line in enumerate(handle, 1):
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            if record.get("type") != "event_msg":
                continue
            payload = record.get("payload") or {}
            if payload.get("type") != "user_message":
                continue
            message = payload.get("message")
            if not isinstance(message, str):
                continue
            yield {
                "line": line_no,
                "ts": record.get("timestamp", ""),
                "message": redact(strip_ansi(message)),
            }


def iter_user_turns(path: Path):
    """Yield user messages plus bounded assistant context for the same turn."""
    previous_agent = ""
    current = None

    def finish_current():
        nonlocal current
        if current is None:
            return None
        item = current
        current = None
        return item

    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line_no, line in enumerate(handle, 1):
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            if record.get("type") != "event_msg":
                continue
            payload = record.get("payload") or {}
            payload_type = payload.get("type")

            if payload_type == "user_message":
                pending = finish_current()
                if pending is not None:
                    yield pending
                message = payload.get("message")
                if not isinstance(message, str):
                    continue
                current = {
                    "line": line_no,
                    "ts": record.get("timestamp", ""),
                    "message": redact(strip_ansi(message)),
                    "previous_agent": previous_agent,
                    "first_agent": "",
                    "final_agent": "",
                }
                continue

            if payload_type == "agent_message":
                message = payload.get("message")
                if not isinstance(message, str) or not message.strip():
                    continue
                previous_agent = message
                if current is not None:
                    if not current["first_agent"]:
                        current["first_agent"] = message
                    current["final_agent"] = message
                continue

            if payload_type == "task_complete" and current is not None:
                last_agent = payload.get("last_agent_message")
                if isinstance(last_agent, str) and last_agent.strip():
                    current["final_agent"] = last_agent
                    previous_agent = last_agent
                pending = finish_current()
                if pending is not None:
                    yield pending

    pending = finish_current()
    if pending is not None:
        yield pending


def build(args: argparse.Namespace) -> dict:
    session_path = Path(args.session).expanduser()
    out_path = Path(args.out)
    stats_path = Path(args.stats)
    session_id = args.session_id or session_id_from_path(session_path)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    stats_path.parent.mkdir(parents=True, exist_ok=True)

    tag_counts: Counter[str] = Counter()
    context_counts: Counter[str] = Counter()
    message_count = 0
    raw_chars = 0
    packed_chars = 0
    context_chars = 0
    context_truncated = 0

    with out_path.open("w", encoding="utf-8") as out:
        out.write("# Codex User Message Corpus\n\n")
        out.write(f"source: {session_path}\n")
        out.write(f"session_id: {session_id}\n")
        out.write("record_kind: event_msg.user_message\n")
        if args.include_agent_context:
            out.write(
                "note: generated temporary audit corpus; each record includes bounded assistant context "
                "snippets for uptake analysis, not full assistant/tool evidence\n\n"
            )
        else:
            out.write("note: generated temporary audit corpus; do not treat assistant/tool output as included evidence\n\n")

        iterator = iter_user_turns(session_path) if args.include_agent_context else iter_user_messages(session_path)
        for message_count, item in enumerate(iterator, 1):
            if args.max_records and message_count > args.max_records:
                message_count -= 1
                break
            message = item["message"]
            tags = tags_for(message)
            tag_counts.update(tags)
            raw_chars += len(message)
            attrs = {
                "id": f"u{message_count:06d}",
                "ts": item["ts"],
                "session": session_id,
                "source_line": str(item["line"]),
                "chars": str(len(message)),
                "tags": ",".join(tags),
            }
            attr_text = " ".join(f'{key}="{html.escape(value, quote=True)}"' for key, value in attrs.items())
            chunk_parts = [f"<record {attr_text}>\n<user_message>\n<![CDATA[\n{cdata_safe(message)}\n]]>\n</user_message>\n"]
            if args.include_agent_context:
                for kind in ("previous_agent", "first_agent", "final_agent"):
                    text, truncated = clip_context(item.get(kind, ""), args.agent_context_chars)
                    if not text:
                        continue
                    context_counts[kind] += 1
                    context_chars += len(text)
                    context_truncated += int(truncated)
                    chunk_parts.append(
                        f'<agent_context kind="{kind}" chars="{len(text)}" truncated="{str(truncated).lower()}">\n'
                        f"<![CDATA[\n{cdata_safe(text)}\n]]>\n</agent_context>\n"
                    )
            chunk_parts.append("</record>\n\n")
            chunk = "".join(chunk_parts)
            packed_chars += len(chunk)
            out.write(chunk)

    stats = {
        "source": str(session_path),
        "output": str(out_path),
        "session_id": session_id,
        "record_kind": "event_msg.user_message",
        "messages": message_count,
        "raw_chars": raw_chars,
        "agent_context_enabled": bool(args.include_agent_context),
        "agent_context_chars_limit": args.agent_context_chars if args.include_agent_context else 0,
        "agent_context_chars": context_chars,
        "agent_context_truncated": context_truncated,
        "agent_context_counts": dict(context_counts.most_common()),
        "packed_chars": packed_chars,
        "rough_tokens_chars_per_3": round(packed_chars / 3),
        "rough_tokens_chars_per_4": round(packed_chars / 4),
        "tag_counts": dict(tag_counts.most_common()),
    }
    stats_path.write_text(json.dumps(stats, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return stats


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session", required=True, type=existing_file_arg, help="Codex JSONL session path")
    parser.add_argument("--session-id", default="", help="Override session id in record attributes")
    parser.add_argument("--out", default=str(DEFAULT_OUT), help="Output corpus path")
    parser.add_argument("--stats", default=str(DEFAULT_STATS), help="Output stats JSON path")
    parser.add_argument("--max-records", type=int, default=0, help="Limit records for sampling")
    parser.add_argument(
        "--include-agent-context",
        action="store_true",
        help="Include bounded previous/first/final assistant snippets per user turn",
    )
    parser.add_argument(
        "--agent-context-chars",
        type=int,
        default=120,
        help="Maximum chars per assistant context snippet",
    )
    args = parser.parse_args()
    if args.include_agent_context and args.out == str(DEFAULT_OUT):
        args.out = str(DEFAULT_CONTEXT_OUT)
    if args.include_agent_context and args.stats == str(DEFAULT_STATS):
        args.stats = str(DEFAULT_CONTEXT_STATS)
    stats = build(args)
    print(json.dumps(stats, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
