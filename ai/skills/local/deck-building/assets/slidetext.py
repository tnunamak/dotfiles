#!/usr/bin/env python3
"""Surgical text edits on a native Google Slides deck.

Reads and writes ONLY text, by element id. Never touches layout, images, or
anything the human moved in the browser.

    ./slidetext.py dump [--slide N]        show every text element with its id
    ./slidetext.py set <objectId> <text>   replace one element's text
    ./slidetext.py setfile <objectId> <f>  replace from a file (multi-line)
    ./slidetext.py apply <edits.json>      batch: [{"id": "...", "text": "..."}]
    ./slidetext.py notes <slideIndex> <f>  replace a slide's speaker notes

Deck id comes from PDPP_NATIVE_DECK_ID, or --deck.
Auth reuses the workspace-mcp credentials already on disk.
"""
import argparse, glob, json, os, sys

from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

CRED_DIR = os.path.expanduser("~/.config/workspace-mcp/credentials")
DEFAULT_DECK = os.environ.get(
    "PDPP_NATIVE_DECK_ID", "1w_oMmzvIsqUlrcsoFMZ_59yi_6uKTHcIWA_nBNHtVcg"
)


def service():
    files = glob.glob(os.path.join(CRED_DIR, "*.json"))
    if not files:
        sys.exit(f"no credentials in {CRED_DIR}; authorize workspace-mcp first")
    blob = json.load(open(files[0]))
    creds = Credentials(
        token=blob.get("token") or blob.get("access_token"),
        refresh_token=blob.get("refresh_token"),
        token_uri=blob.get("token_uri", "https://oauth2.googleapis.com/token"),
        client_id=blob.get("client_id"),
        client_secret=blob.get("client_secret"),
        scopes=blob.get("scopes"),
    )
    return build("slides", "v1", credentials=creds, cache_discovery=False)


def text_of(element):
    tr = element.get("shape", {}).get("text")
    if not tr:
        return None
    out = []
    for el in tr.get("textElements", []):
        run = el.get("textRun")
        if run:
            out.append(run.get("content", ""))
    return "".join(out).strip()


def walk(elements, depth=0):
    for el in elements:
        yield el, depth
        grp = el.get("elementGroup")
        if grp:
            yield from walk(grp.get("children", []), depth + 1)


def cmd_dump(svc, deck, args):
    pres = svc.presentations().get(presentationId=deck).execute()
    for i, slide in enumerate(pres.get("slides", []), start=1):
        if args.slide and i != args.slide:
            continue
        print(f"\n--- slide {i}  ({slide['objectId']})")
        for el, depth in walk(slide.get("pageElements", [])):
            t = text_of(el)
            if t:
                pad = "  " * depth
                flat = t.replace("\n", " ⏎ ")
                print(f"  {pad}{el['objectId']:<28} {flat[:88]}")


def replace_requests(object_id, new_text, has_existing=True):
    reqs = []
    if has_existing:
        reqs.append({"deleteText": {"objectId": object_id, "textRange": {"type": "ALL"}}})
    if new_text:
        reqs.append(
            {"insertText": {"objectId": object_id, "insertionIndex": 0, "text": new_text}}
        )
    return reqs


def cmd_set(svc, deck, args):
    text = args.text if args.cmd == "set" else open(args.file).read().rstrip("\n")
    svc.presentations().batchUpdate(
        presentationId=deck, body={"requests": replace_requests(args.object_id, text)}
    ).execute()
    print(f"set {args.object_id}")


def cmd_apply(svc, deck, args):
    edits = json.load(open(args.file))
    reqs = []
    for e in edits:
        reqs += replace_requests(e["id"], e["text"])
    if not reqs:
        print("nothing to do")
        return
    svc.presentations().batchUpdate(
        presentationId=deck, body={"requests": reqs}
    ).execute()
    print(f"applied {len(edits)} edit(s) in one batch")


def cmd_notes(svc, deck, args):
    pres = svc.presentations().get(presentationId=deck).execute()
    slides = pres.get("slides", [])
    if not (1 <= args.slide <= len(slides)):
        sys.exit(f"slide {args.slide} out of range (deck has {len(slides)})")
    slide = slides[args.slide - 1]
    notes_page = slide.get("slideProperties", {}).get("notesPage", {})
    shape_id = notes_page.get("notesProperties", {}).get("speakerNotesObjectId")
    if not shape_id:
        sys.exit("no speaker-notes shape on that slide")
    existing = ""
    for el in notes_page.get("pageElements", []):
        if el.get("objectId") == shape_id:
            existing = text_of(el) or ""
    text = open(args.file).read().rstrip("\n")
    svc.presentations().batchUpdate(
        presentationId=deck,
        body={"requests": replace_requests(shape_id, text, bool(existing))},
    ).execute()
    print(f"notes set on slide {args.slide}")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--deck", default=DEFAULT_DECK)
    sub = p.add_subparsers(dest="cmd", required=True)

    d = sub.add_parser("dump"); d.add_argument("--slide", type=int)
    s = sub.add_parser("set"); s.add_argument("object_id"); s.add_argument("text")
    sf = sub.add_parser("setfile"); sf.add_argument("object_id"); sf.add_argument("file")
    a = sub.add_parser("apply"); a.add_argument("file")
    n = sub.add_parser("notes"); n.add_argument("slide", type=int); n.add_argument("file")

    args = p.parse_args()
    svc = service()
    {"dump": cmd_dump, "set": cmd_set, "setfile": cmd_set,
     "apply": cmd_apply, "notes": cmd_notes}[args.cmd](svc, args.deck, args)


if __name__ == "__main__":
    main()
