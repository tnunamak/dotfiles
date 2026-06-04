#!/usr/bin/env python3
"""Select contrastive steering-audit windows from steering-spikes JSON."""

from __future__ import annotations

import argparse
import json
import random
from collections import defaultdict
from pathlib import Path


DEFAULT_SPIKES = Path("tmp/workstreams/agent-steering-audit-spikes.json")


def add_unique(selected: list[dict], row: dict, label: str) -> bool:
    if any(item["bucket"] == row["bucket"] for item in selected):
        return False
    selected.append({"label": label, **row})
    return True


def select(spikes: dict, seed: int, target: int) -> list[dict]:
    cw = spikes["contrastive_windows"]
    selected: list[dict] = []

    quota_sources = [
        ("quiet_high_output", cw["quiet_high_output"], 6),
        ("high_output_high_friction", cw["high_output_high_friction"], 6),
        ("coordination_pressure", cw["coordination_pressure"], 5),
        ("positive_low_correction", cw["positive_low_correction"], 3),
        ("raw_flying_score", spikes["top_flying_windows"], 3),
        ("raw_friction_score", spikes["top_friction_windows"], 3),
    ]
    for label, rows, quota in quota_sources:
        added = 0
        for row in rows:
            if add_unique(selected, row, label):
                added += 1
            if added >= quota:
                break

    # Control windows are drawn from windows already surfaced by some ranked
    # list, but not selected. This is not a full random sample; it is a cheap
    # guard against only reading the top examples.
    candidate_controls = {}
    for rows in [spikes["top_flying_windows"], spikes["top_friction_windows"], *cw.values()]:
        if isinstance(rows, dict):
            continue
        for row in rows:
            candidate_controls[row["bucket"]] = row
    pool = [row for bucket, row in candidate_controls.items() if not any(s["bucket"] == bucket for s in selected)]
    rng = random.Random(seed)
    rng.shuffle(pool)
    for row in pool:
        add_unique(selected, row, "ranked_control")
        if len(selected) >= target:
            break

    return selected[:target]


def phase_guess(bucket: str) -> str:
    if bucket < "2026-04-22":
        return "early RI construction / autonomy calibration"
    if bucket < "2026-04-28":
        return "workstream/report flood and live validation"
    if bucket < "2026-05-08":
        return "OpenSpec closeout / RI ownership"
    if bucket < "2026-05-20":
        return "connectors / remote-browser / collector design"
    if bucket < "2026-05-26":
        return "hosted MCP / records / connector-green pressure"
    return "late ABD / closure / management pressure"


def render(selected: list[dict], seed: int) -> str:
    lines = [
        "# Steering Calibration Window Manifest",
        "",
        "Status: deterministic selection aid, not final labels.",
        "",
        f"Random seed: `{seed}`",
        f"Selected windows: `{len(selected)}`",
        "",
        "| # | Bucket | Selection Label | Phase Guess | Turns | Repair | Corrections | Positives | Dispatch | Evidence |",
        "|---:|---|---|---|---:|---:|---:|---:|---:|---:|",
    ]
    for idx, row in enumerate(selected, 1):
        repair = row.get("repair_turns", row.get("corrections", ""))
        lines.append(
            f"| {idx} | `{row['bucket']}` | {row['label']} | {phase_guess(row['bucket'])} | "
            f"{row.get('turns','')} | {repair} | {row.get('corrections','')} | "
            f"{row.get('positives','')} | {row.get('dispatch_turns','')} | {row.get('evidence','')} |"
        )

    by_label = defaultdict(int)
    for row in selected:
        by_label[row["label"]] += 1
    lines.extend(["", "## Counts By Selection Label", ""])
    for label, count in sorted(by_label.items()):
        lines.append(f"- {label}: {count}")

    lines.extend(
        [
            "",
            "## Audit Card Fields",
            "",
            "- target strand/object",
            "- phase label",
            "- user's steering act",
            "- agent's claimed operating mode",
            "- actual next actions",
            "- evidence outside final messages when available",
            "- later repair or acceptance",
            "- classification",
            "- reusable primitive or counterexample",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--spikes", default=str(DEFAULT_SPIKES))
    parser.add_argument("--seed", type=int, default=5282026)
    parser.add_argument("--target", type=int, default=24)
    args = parser.parse_args()
    spikes = json.loads(Path(args.spikes).read_text())
    print(render(select(spikes, args.seed, args.target), args.seed))


if __name__ == "__main__":
    main()
