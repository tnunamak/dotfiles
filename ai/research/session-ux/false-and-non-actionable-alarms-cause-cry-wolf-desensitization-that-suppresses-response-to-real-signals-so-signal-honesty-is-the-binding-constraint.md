---
title: "False and non-actionable alarms cause 'cry-wolf' desensitization that suppresses response to genuine signals — false alarms damage trust more than misses do, and once ~85–99% of signals are non-actionable operators disable or ignore the whole channel — so per-signal truthfulness is the binding constraint, not signal richness"
date: 2026-07-16
topic: session-ux
tags: [cry-wolf, alarm-fatigue, false-alarm, trust-calibration, desensitization, positive-predictive-value, freshness-decay]
status: draft
sources: [tjc-alarm-fatigue, tjc-sentinel-alert, cry-wolf-atc, cry-wolf-breznitz, false-alarm-vs-miss]
source_session: unknown
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable.
-->

## CLAIMS

- The "cry-wolf" effect (Breznitz 1983) is that a high false-alarm rate erodes operator trust so that alerts are ignored over time, even when correct — a self-reinforcing decay of the whole channel. [cry-wolf-breznitz] [false-alarm-vs-miss]
- Medical alarm fatigue is desensitization from over-exposure: an estimated 85–99% of clinical alarm signals do NOT require intervention, so clinicians become immune to the sound and miss or delay response to the ones that matter — volume of non-actionable alarms is the direct cause. [tjc-alarm-fatigue] [tjc-sentinel-alert]
- Desensitized operators actively defeat the system: they turn alarm volume down, turn alarms off, or set limits outside safe bounds — i.e. once a channel is untrusted, humans disable it rather than tune it, converting nuisance into danger. [tjc-alarm-fatigue]
- The harm is documented and fatal: the Joint Commission's sentinel-event database logged 98 alarm-related events (80 deaths) Jan 2009–Jun 2012, with alarm fatigue named the most common contributing factor; an FDA database logged 566 alarm-related deaths 2005–2010. [tjc-sentinel-alert] [tjc-alarm-fatigue]
- False alarms are quantitatively MORE harmful to operator trust and performance than misses, and they act via a distinct cognitive route: false alarms degrade *compliance* (acting when it alarms) while misses degrade *reliance* (trusting silence) — they are two separate types of trust, so a system can be trusted to be quiet yet not trusted to be right, or vice versa. [false-alarm-vs-miss]
- Cry-wolf strength tracks positive predictive value (PPV = P(real | alarm)), not just raw false-alarm rate: compliance falls as PPV falls, so a signal type with low PPV poisons response even at low absolute volume. [false-alarm-vs-miss]
- Field evidence tempers the lab result: in air-traffic control ~45% of conflict alerts were false, yet controllers did not measurably miss true alerts — because they had an independent way to anticipate the real event (they issued trajectory changes before the alert), i.e. a redundant, higher-trust information source blunts cry-wolf. [cry-wolf-atc]

## SOURCES

**tjc-alarm-fatigue**
URL: https://www.ncbi.nlm.nih.gov/books/NBK555522/
Accessed: 2026-07-16
Quote: "It is estimated that 85% to 99% of alarm signals do not require clinical intervention, and thus clinicians become desensitized or immune to the sounds... clinicians may turn down the volume of the alarm, turn it off, or adjust the settings outside safe and appropriate limits."

**tjc-sentinel-alert**
URL: https://pubmed.ncbi.nlm.nih.gov/23776996/
Accessed: 2026-07-16
Quote: "the sentinel event database includes 98 alarm-related events (80 of which resulted in death) between 2009 and June 2012... alarm fatigue was the most common contributing factor."

**cry-wolf-atc**
URL: https://journals.sagepub.com/doi/10.1177/0018720809344720
Accessed: 2026-07-16
Quote: "Forty-five percent of the alerts were false... Although centers with more false alerts contributed to more nonresponses, there was no evidence that these were nonresponses to true alerts... controllers showed desirable anticipatory behavior by issuing trajectory changes prior to the alert."

**cry-wolf-breznitz**
URL: https://stars.library.ucf.edu/rtd/3614/
Accessed: 2026-07-16
Quote: "Breznitz... 'Cry-wolf: The psychology of false alarms' (1983); the cry-wolf effect, where users ignore the alerts over time, even when they may be correct."

**false-alarm-vs-miss**
URL: https://apps.dtic.mil/sti/tr/pdf/ADA496817.pdf
Accessed: 2026-07-16
Quote: "automation false alarms not only produce qualitatively different effects on operator trust than do automation misses, but that they are also quantitatively more harmful... false alarms and misses affect compliance and reliance via independent cognitive processes."

## SYNTHESIS

This is the entry that names the single failure mode Tim already flagged: a "waiting for input" glyph that lied destroyed trust in the whole system. That is the cry-wolf effect, and the literature says it is not a minor UX bug — it is the dominant risk. Three design consequences:

1. **Per-signal truthfulness dominates signal richness.** The binding constraint is PPV, not how much info a label carries. A rich label that is right 70% of the time is worse than a sparse label that is right 99% of the time, because once trust decays the operator disables the channel (turns the volume down / stops looking) and *even the correct signals stop working*. So the redesign should prefer under-claiming: a signal fires only when the underlying state is verifiable with high confidence (e.g. agent-blocked detected from the JSONL/idle-state contract, per the existing multi-agent-orchestration corpus, NOT from screen-scraping a glyph that can lie). If confidence is low, degrade to a passive indicator, never a push.

2. **False alarms and misses need separate budgets.** Compliance (act-on-alarm) and reliance (trust-the-silence) are different trusts. For the top tier (agent-blocked), a false alarm is the expensive error — protect PPV even at the cost of a slightly slower alert. For "agent-finished," a *miss* is cheaper (Tim will find it eventually on the dashboard) so bias toward silence there. Don't apply one threshold to both.

3. **Freshness/decay = a signal nobody acts on must self-demote, and a stale signal must self-retract.** The medical data shows the killing move is the operator disabling a channel that nagged. So: a signal that has been shown for N minutes without being acted on should DECAY down the tiers (push → passive indicator → dashboard-only), never re-fire or escalate on its own — re-nagging is precisely what trains desensitization. And a signal whose underlying state has changed (the agent got unblocked by something else, the command's window was closed) must retract immediately, the analog of Plaid's LOGIN_REPAIRED "stop nagging" webhook already in the corpus. The ATC finding gives the escape hatch: because Tim has an independent high-trust channel (he can just look at the window), the passive/dashboard layer can safely absorb everything the interrupt layer suppresses — suppression is safe *because* the truth stays inspectable, so it is never dishonest to withhold a low-PPV signal from the attention channel.
