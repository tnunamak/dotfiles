#!/usr/bin/env python3
"""Mechanical pairing: Callum touches a file someone else changed within WINDOW days.
No judgment — a pair is a CANDIDATE, not a finding."""
import json,glob,os,sys
from datetime import date
WINDOW=21
def d(s):
    y,m,dd=map(int,s.split("-")); return date(y,m,dd)
pairs=[]; stats={}
for f in sorted(glob.glob("raw/commits/*.jsonl")):
    repo=os.path.basename(f)[:-6]
    cs=[json.loads(l) for l in open(f)]
    cs.sort(key=lambda c:c["date"])
    callum=[c for c in cs if "callum" in (c["an"]+c["ae"]).lower()]
    other =[c for c in cs if "callum" not in (c["an"]+c["ae"]).lower()]
    # index others' commits by file
    byfile={}
    for c in other:
        for fp in c["files"]: byfile.setdefault(fp,[]).append(c)
    n=0
    for cc in callum:
        seen={}
        for fp in cc["files"]:
            for oc in byfile.get(fp,[]):
                delta=(d(cc["date"])-d(oc["date"])).days
                if 0<=delta<=WINDOW:
                    k=oc["sha"]
                    seen.setdefault(k,{"their":oc,"files":set()})["files"].add(fp)
        for k,v in seen.items():
            pairs.append({"repo":repo,"callum_sha":cc["sha"],"callum_date":cc["date"],
                "callum_subject":cc["subject"],"their_sha":v["their"]["sha"],
                "their_author":v["their"]["an"],"their_date":v["their"]["date"],
                "their_subject":v["their"]["subject"],
                "shared_files":sorted(v["files"]),"n_shared":len(v["files"])})
            n+=1
    stats[repo]=(len(callum),len(other),n)
with open("pairs/pairs.jsonl","w") as o:
    for p in sorted(pairs,key=lambda p:p["callum_date"],reverse=True): o.write(json.dumps(p)+"\n")
print(f"{'repo':<28}{'callum':>7}{'other':>7}{'pairs':>7}")
for r,(a,b,n) in sorted(stats.items(),key=lambda x:-x[1][2]): print(f"{r:<28}{a:>7}{b:>7}{n:>7}")
print(f"\nTOTAL PAIRS: {len(pairs)}")
