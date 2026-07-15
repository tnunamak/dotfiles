# John Carmack on Code Quality — Verified Primary Sources

## 1. Functional Programming / Programmers Don't Understand All Code States

**Source:** "Functional Programming in C++"
- **Published:** Originally on AltDevBlog (2011–2012); archived at multiple mirrors
- **Primary URL:** https://web.archive.org/web/2018/https://sevangelatos.com/john-carmack-on/ (Sevangelatos mirror of original)
- **Status:** PRIMARY — direct post by Carmack; original AltDevBlog now defunct (SSL cert expired)

**Direct Quote (Verbatim):**
> "A large fraction of the flaws in software development are due to programmers not fully understanding all the possible states their code may execute in. In a multithreaded environment, the lack of understanding and the resulting problems are greatly amplified, almost to the point of panic if you are paying attention. Programming in a functional style makes the state presented to your code explicit, which makes it much easier to reason about, and, in a completely pure system, makes thread race conditions impossible."

**Reliability:** HIGH — preserved by community archive (Sevangelatos); appears identical to Gamasutra Game Developer coverage

---

## 2. Pure Functions / Explicit State

**Source:** Same article ("Functional Programming in C++")
- **Published:** 2011–2012 on AltDevBlog
- **Primary URL:** https://web.archive.org/web/2018/https://sevangelatos.com/john-carmack-on/

**Direct Quote (Verbatim):**
> "A pure function all it does is return one or more computed values based on the parameters. It has no logical side effects. This is an abstraction of course; every function has side effects at the CPU level, and most at the heap level, but the abstraction is still valuable."

**Reliability:** HIGH — same primary source as #1

---

## 3. Action Items: Survey Functions for External State and Side Effects

**Source:** Same article ("Functional Programming in C++")
- **Published:** 2011–2012 on AltDevBlog
- **Primary URL:** https://web.archive.org/web/2018/https://sevangelatos.com/john-carmack-on/

**Direct Quote (Verbatim, from "Action Items" section):**
> "Survey some non-trivial functions in your codebase and track down every bit of external state they can reach, and all possible modifications they can make. This makes great documentation to stick in a comment block, even if you don't do anything with it. If the function can trigger, say, a screen update through your render system, you can just throw your hands up in the air and declare the set of all effects beyond human understanding."

> "The next task you undertake, try from the beginning to think about it in terms of the real computation that is going on. Gather up your input, pass it to a pure function, then take the results and do something with it."

> "Modify some of your utility object code to return new copies instead of self-mutating, and try throwing const in front of practically every non-iterator variable you use."

**Reliability:** HIGH — same primary source, explicit action items section

---

## 4. Parallel Programming and Object-Oriented State Problems

**Source:** Same article ("Functional Programming in C++")
- **Published:** 2011–2012 on AltDevBlog
- **Primary URL:** https://web.archive.org/web/2018/https://sevangelatos.com/john-carmack-on/

**Direct Quote (Verbatim):**
> "When you start thinking about running, say, all the characters in a game world in parallel, it starts sinking in that the object oriented approach of updating objects has some deep difficulties in parallel environments. Maybe if all of the object just referenced a read only version of the world state, and we copied over the updated version at the end of the frame… Hey, wait a minute…"

**Reliability:** HIGH — same primary source; demonstrates Carmack's move from OOP toward functional/immutable patterns

---

## UNVERIFIED / NOT FOUND

### Event Queue / Quake Determinism
- **Status:** UNFOUND in primary sources
- **Notes:** Frequently cited as "Quake event-driven architecture" or "sys_event centralization" enabling journaling/replay, but I could not locate a direct Carmack quote or detailed description in the fetched sources. Wikipedia mentions QuakeCon talks but does not detail this architecture. The GitHub .plan archive was sparse and did not contain relevant entries. 
- **Recommendation:** Needs **QuakeCon talk transcript or video** (post–2010s, when Carmack spoke more openly); alternatively, fetch archived .plan files from early 2000s or Quake-era documentation

### Inlining / Keeping Behavior Visible at Call Site
- **Status:** UNFOUND in primary sources
- **Notes:** Not present in the "Functional Programming in C++" article. The principle (preferring inline/explicit over call-indirection) aligns with Carmack's other statements but no direct quote located.
- **Recommendation:** Needs **QuakeCon talks, .plan files, or interviews** (1990s–2000s era); likely in technical deep-dives on Quake/Doom rendering or engine design

### "Boring" / Long Plain Explicit Functions Over Clever Abstraction
- **Status:** UNFOUND in primary sources
- **Notes:** The sentiment matches Carmack's writing style and conclusions (prefer explicit, understandable code) but no verbatim quote found in the fetched material.
- **Recommendation:** Needs **interviews, QuakeCon Q&A, or later-career statements** (2010s+); possibly paraphrased from his actual word choice in talks or forums

---

## Summary

**Verified (3 positions, 1 source):**
1. Programmers fail to understand all possible code states → functional/pure style makes state explicit
2. Pure function definition and side-effect abstraction
3. Action items: survey external state, use pure functions, prefer immutability (copy-return over self-mutation)
4. Parallel programming context for functional style preference

**Needs Original Source:**
- Event queue / Quake determinism architecture
- Inlining / local reasoning
- Distrust of abstraction / boring functions

**Source Reliability:**
- Sevangelatos mirror (web.archive.org) is a community-curated archive; the original AltDevBlog source is defunct but this appears to be the canonical rescue copy
- Gamasutra Game Developer may have also published or rehosted; worth checking if deeper archival needed
