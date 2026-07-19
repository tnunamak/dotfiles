#!/usr/bin/env python3
"""Mechanical checker for a subset of ASD-STE100 (Simplified Technical English) rules.

Catches what a script CAN catch: word/sentence/paragraph limits, banned punctuation,
contractions, passive/auxiliary constructions, banned "-ing" verbs, phrasal verbs, Latin
abbreviations, and words absent from the (sample) approved dictionary. It cannot judge
approved *meaning* (rule 1.3), technical-noun categorization (1.5-1.11), or whether a
sentence's logic is genuinely simultaneous (5.2) — those need a reader, not a regex.

Usage:
    ste_lint.py FILE [FILE ...]
    echo "some text" | ste_lint.py -
    ste_lint.py --json FILE   # machine-readable output for a checker agent

Exit status: 0 if no findings, 1 if findings were reported.
"""

import argparse
import json
import re
import sys
from pathlib import Path

REFERENCES_DIR = Path(__file__).resolve().parent.parent / "references"
DICTIONARY_PATH = REFERENCES_DIR / "dictionary.tsv"

PROCEDURAL_MAX_WORDS = 20
DESCRIPTIVE_MAX_WORDS = 25
MAX_SENTENCES_PER_PARAGRAPH = 6

CONTRACTIONS = re.compile(r"\b\w+'(?:t|re|ve|ll|d|s|m)\b", re.IGNORECASE)
SEMICOLON = re.compile(r";")
LATIN_ABBREVIATIONS = re.compile(r"\b(e\.g\.|i\.e\.|etc\.)", re.IGNORECASE)

# Rule 3.4: auxiliary + past participle passive/modal-passive constructions.
AUXILIARY_PASSIVE = re.compile(
    r"\b(?:is|are|was|were|be|been|being)\s+(?:to\s+be\s+)?\w+ed\b"
    r"|\b(?:can|could|must|will|would|should|may|might)\s+be\s+\w+ed\b"
    r"|\bhas\s+been\s+\w+ed\b"
    r"|\bhave\s+been\s+\w+ed\b",
    re.IGNORECASE,
)

# Rule 3.5: "-ing" used as a verb (after "is/are/was/were/be/been/being", or "am").
ING_AS_VERB = re.compile(
    r"\b(?:am|is|are|was|were|be|been|being)\s+\w+ing\b", re.IGNORECASE
)

# Rule 9.3: a sample of common phrasal verbs STE explicitly bans in favor of one-word verbs.
PHRASAL_VERBS = {
    "put out": "extinguish",
    "carry out": "do / perform",
    "take off": "remove",
    "put on": "install / wear",
    "turn on": "energize / start",
    "turn off": "de-energize / stop",
    "set up": "install / configure",
    "back up": "support / save a copy of",
    "look into": "examine",
    "find out": "determine",
    "come up with": "produce",
    "get rid of": "remove / discard",
    "hook up": "connect",
    "point out": "show",
}

WORD_RE = re.compile(r"[A-Za-z][A-Za-z'-]*")
SENTENCE_SPLIT_RE = re.compile(r"(?<=[.!?])\s+")


def load_dictionary(path=DICTIONARY_PATH):
    """word.lower() -> (pos, approved: bool, alternatives: list[str])"""
    entries = {}
    if not path.exists():
        return entries
    with path.open(encoding="utf-8") as f:
        next(f, None)  # header
        for line in f:
            line = line.rstrip("\n")
            if not line:
                continue
            parts = line.split("\t")
            while len(parts) < 4:
                parts.append("")
            word, pos, approved, alternatives = parts[0], parts[1], parts[2], parts[3]
            key = word.lower()
            entries.setdefault(key, []).append(
                (pos, approved == "y", [a.strip() for a in alternatives.split(";") if a.strip()])
            )
    return entries


def count_words(sentence):
    return len(WORD_RE.findall(sentence))


def split_sentences(paragraph):
    return [s.strip() for s in SENTENCE_SPLIT_RE.split(paragraph.strip()) if s.strip()]


def split_paragraphs(text):
    return [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]


def check_text(text, mode="procedural", dictionary=None):
    """Returns a list of finding dicts: {rule, severity, message, excerpt}."""
    findings = []
    max_words = PROCEDURAL_MAX_WORDS if mode == "procedural" else DESCRIPTIVE_MAX_WORDS

    for m in SEMICOLON.finditer(text):
        findings.append(_finding("8.1", "error", "Semicolon not allowed — split into two sentences.", _excerpt(text, m)))

    for m in CONTRACTIONS.finditer(text):
        findings.append(_finding("4.2", "error", "Contraction not allowed — spell out the words.", m.group(0)))

    for m in LATIN_ABBREVIATIONS.finditer(text):
        findings.append(_finding("GR-6", "warning", "Latin abbreviation — spell out in English or omit.", m.group(0)))

    for m in AUXILIARY_PASSIVE.finditer(text):
        findings.append(_finding("3.4/3.6", "warning", "Likely passive/auxiliary construction — prefer active voice, imperative for instructions.", m.group(0)))

    for m in ING_AS_VERB.finditer(text):
        findings.append(_finding("3.5", "warning", '"-ing" used as a verb — only approved as a technical noun or noun modifier.', m.group(0)))

    lowered = text.lower()
    for phrase, alt in PHRASAL_VERBS.items():
        if phrase in lowered:
            findings.append(_finding("9.3", "warning", f'Phrasal verb "{phrase}" — use a one-word verb instead (e.g. "{alt}").', phrase))

    for paragraph in split_paragraphs(text):
        sentences = split_sentences(paragraph)
        if len(sentences) > MAX_SENTENCES_PER_PARAGRAPH:
            findings.append(_finding("6.6", "warning", f"Paragraph has {len(sentences)} sentences (max {MAX_SENTENCES_PER_PARAGRAPH}).", paragraph[:80] + "..."))
        for sentence in sentences:
            wc = count_words(sentence)
            if wc > max_words:
                rule = "5.1" if mode == "procedural" else "6.3"
                findings.append(_finding(rule, "error", f"Sentence has {wc} words (max {max_words} for {mode} text).", sentence[:100] + ("..." if len(sentence) > 100 else "")))

    if dictionary:
        findings.extend(_check_dictionary(text, dictionary))

    return findings


def _check_dictionary(text, dictionary):
    findings = []
    seen_not_approved = set()
    for match in WORD_RE.finditer(text):
        word = match.group(0)
        key = word.lower()
        if key in seen_not_approved:
            continue
        entries = dictionary.get(key)
        if entries is None:
            continue  # not in our sample — silently skip, don't flag words we have no data on
        not_approved = [e for e in entries if not e[1]]
        approved = [e for e in entries if e[1]]
        if not_approved and not approved:
            seen_not_approved.add(key)
            alts = not_approved[0][2]
            alt_text = f' Try: {", ".join(alts)}.' if alts else ""
            findings.append(_finding("1.3/9.2", "info", f'"{word}" is not an approved STE word.{alt_text}', word))
    return findings


def _finding(rule, severity, message, excerpt):
    return {"rule": rule, "severity": severity, "message": message, "excerpt": excerpt}


def _excerpt(text, match, radius=30):
    start = max(0, match.start() - radius)
    end = min(len(text), match.end() + radius)
    return text[start:end].strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("files", nargs="+", help='Files to check, or "-" for stdin')
    parser.add_argument("--mode", choices=["procedural", "descriptive"], default="procedural", help="Which word-count limit to apply (default: procedural, 20 words)")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of human-readable text")
    parser.add_argument("--no-dictionary", action="store_true", help="Skip the approved-word dictionary check")
    args = parser.parse_args()

    dictionary = None if args.no_dictionary else load_dictionary()
    any_findings = False

    for filename in args.files:
        text = sys.stdin.read() if filename == "-" else Path(filename).read_text(encoding="utf-8")
        findings = check_text(text, mode=args.mode, dictionary=dictionary)
        if findings:
            any_findings = True
        if args.json:
            print(json.dumps({"file": filename, "findings": findings}, indent=2))
        else:
            label = filename if filename != "-" else "(stdin)"
            if not findings:
                print(f"{label}: no findings")
                continue
            print(f"{label}: {len(findings)} finding(s)")
            for f in findings:
                print(f"  [{f['severity']}] rule {f['rule']}: {f['message']}")
                print(f"      → {f['excerpt']!r}")

    sys.exit(1 if any_findings else 0)


if __name__ == "__main__":
    main()
