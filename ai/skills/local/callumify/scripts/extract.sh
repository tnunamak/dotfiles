#!/usr/bin/env bash
# Mechanical extraction only. No judgment. Safe to re-run; skips existing clones.
set -uo pipefail
REPO="$1"; ROOT="$HOME/.tmp/callumify-0818"
CL="$ROOT/clones/$REPO.git"
[ -d "$CL" ] || timeout 600 git clone -q --bare --filter=blob:none \
  "https://github.com/vana-com/$REPO.git" "$CL" 2>/dev/null || { echo "CLONE-FAIL $REPO"; exit 1; }
cd "$CL" || exit 1
# every commit (all authors) with files touched — this is the durable substrate
git log --all --date=short \
  --format='@@@%H%x09%an%x09%ae%x09%ad%x09%s' --name-only 2>/dev/null \
| python3 -c '
import sys,json
cur=None
out=open(sys.argv[1],"w")
for line in sys.stdin:
    line=line.rstrip("\n")
    if line.startswith("@@@"):
        if cur: out.write(json.dumps(cur)+"\n")
        p=line[3:].split("\t")
        cur={"sha":p[0],"an":p[1],"ae":p[2],"date":p[3],"subject":p[4] if len(p)>4 else "","files":[]}
    elif line.strip() and cur is not None:
        cur["files"].append(line)
if cur: out.write(json.dumps(cur)+"\n")
out.close()
' "$ROOT/raw/commits/$REPO.jsonl"
N=$(wc -l < "$ROOT/raw/commits/$REPO.jsonl")
C=$(grep -ci 'callum' "$ROOT/raw/commits/$REPO.jsonl" || true)
echo "OK $REPO total=$N callum=$C"
