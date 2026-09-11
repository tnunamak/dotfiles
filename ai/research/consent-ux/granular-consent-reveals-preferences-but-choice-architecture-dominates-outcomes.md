---
title: "Granular consent can reveal preferences, but choice architecture and decision volume dominate outcomes"
date: 2026-09-03
topic: consent-ux
tags: [consent, dark-patterns, privacy-agents, delegation, ux]
status: draft
sources: [nouwens, utz, habib, edpb, ppa-field, ppa-delegation]
source_session: unknown
---

## CLAIMS

- In a scrape of the top 10,000 UK websites, 11.8% of consent interfaces met the study's minimal requirements; in a 40-person experiment, hiding opt-out increased acceptance by 22–23 percentage points and putting granular controls on the first page reduced it by 8–20 points. [nouwens]
- A field experiment with more than 80,000 unique users found that banner position, the number of choices, and framing materially affected consent. [utz]
- In an experiment with 150 participants, select-all defaults increased purposes accepted, harmed recall, and increased regret and perceived deception; merely showing one versus three purposes did not produce a significant effect. [habib]
- EDPB guidance treats extra clicks or time for withdrawal and one-click opt-in without an equivalent direct opt-out as evidence of deceptive design or invalid withdrawal mechanics. [edpb]
- In a 72-person field deployment of a mobile privacy assistant, users adopted 78.7% of recommendations and later changed 5.1%; the study required rooted Android devices. [ppa-field]
- A 1,126-person scenario study found participants exclusively preferred fully autonomous privacy assistants above a decision frequency of roughly one per hour; it measured stated preference rather than longitudinal behavior. [ppa-delegation]

## SOURCES

**nouwens**
URL: https://discovery.ucl.ac.uk/id/eprint/10088400
Accessed: 2026-09-03

**utz**
URL: https://arxiv.org/abs/1909.02638
Accessed: 2026-09-03

**habib**
URL: https://petsymposium.org/popets/2020/popets-2020-0037.pdf
Accessed: 2026-09-03

**edpb**
URL: https://www.edpb.europa.eu/documents/guideline/guidelines-032022-on-deceptive-design-patterns-in-social-media-platform_en
Accessed: 2026-09-03

**ppa-field**
URL: https://www.usenix.org/conference/soups2016/technical-sessions/presentation/liu
Accessed: 2026-09-03
Quote: "78.7% of the recommendations made by the PPA were adopted by users"

**ppa-delegation**
URL: https://www.research-collection.ethz.ch/items/e6e25dc9-187f-4c45-b8c3-45aa8e9d40fa
Accessed: 2026-09-03
Quote: "participants exclusively preferred fully autonomous PPAs"

## SYNTHESIS

More controls do not automatically create more autonomy. Defaults, salience, friction, and decision frequency can dominate the content of the choice and can reduce comprehension. A personal agent is promising because it can amortize privacy labor, but its defaults and recommendations become a new choice architecture. Evaluate it on comprehension, reversals, regret, and time—not acceptance rate. Escalate novel or high-risk terms and log automated choices so the person can inspect and change them.
