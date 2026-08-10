# Personal-data-search-specific ranking norms — prior art

Date: 2026-06-15
Status: captured (informative; fills the gap in PDPP's prior art — all earlier
search research covered *general* search engines, this covers searching YOUR OWN
data: messages, emails, chat history, notes)

## Why this note exists (the gap it closes)

Two prior PDPP research notes —
`lexical-search-ranking-recency-prior-art-2026-06-15.md` and
`lexical-search-freshness-prior-art-2026-06-15.md` — cover **general search**
(Elasticsearch `gauss` decay, Algolia tie-break ladder, Stripe `has_more`,
Postgres FTS normalization, ParadeDB BM25). That body of work answers "how does a
*web/document* search engine blend relevance and recency and signal truncation."

It does **not** answer the question PDPP actually faces: **PDPP search is search
over the user's OWN personal data** — Slack messages, Gmail, ChatGPT/Codex
transcripts, Notion-like notes. Personal-data search ("Personal Information
Management" / PIM retrieval in the literature) has materially different norms from
web search, because:

1. The corpus is **the user's own history**, which they have *seen before*. The
   dominant intent is **re-finding** ("find THAT message I know exists"), not
   discovery.
2. The user typically has **episodic memory** of the item — roughly *when* it
   happened, *who* sent it, *what thread/channel* it was in. Those become
   first-class ranking signals that have no analog in anonymous web search.
3. The corpus is small enough per-user that systems can afford **per-message
   personalization** (a "work graph") that web-scale search cannot.

This note collects the prior art specific to that setting and resolves the four
questions the task posed. It deliberately does not re-derive the general
relevance+recency blend mechanics — those live in the companion note; this is the
*personal-data overlay* on top of them.

---

## 0. The decisive empirical anchor: users prefer DATE over relevance for personal data

The single most important finding in the personal-search literature, because it
directly contradicts the web-search default and reframes the whole question:

**Microsoft Research "Stuff I've Seen" (SIS), Dumais et al., SIGIR 2003** — the
foundational unified personal-data search system (indexed email, files, web
history, calendar with a BM25-based lexical ranker). Their headline, repeatedly
cited as *surprising*:

> "One of the most surprising findings of the study was that participants
> **preferred search results to be ranked by date rather than by relevance**."

The explanation is the crux of personal-data search and recurs everywhere below:

> "Users have a rough idea when they received, modified, or interacted with the
> item they are looking for, and they can therefore leverage dates effectively
> when skimming through the result list."

This is the load-bearing distinction from web search. In web search the user has
**no temporal memory** of an anonymous document, so relevance must do all the
work. In personal-data search the user *was there* — they have an episodic memory
trace (time, sender, context) — so a **date-ordered list is something they can
navigate by recognition**, scanning to the rough time they remember. Date is not
just a tie-break; for personal data it is a *primary navigational axis the user
already holds the key to*.

(Source: surveyed in "Searching Personal Collections", arXiv 2412.12330, which
catalogs SIS as the origin of the date-preference finding.)

This does NOT mean "recency-first" — see §3, the resolution is subtler (it's
"date-as-a-navigable-axis", offered alongside relevance, with the system
defaulting smartly). But it decisively kills the assumption that web search's
"relevance-primary, recency-as-gentle-multiplier" default is automatically right
for personal data.

---

## 1. How best-in-class personal-search products actually rank

Surveyed six leading products. The convergent pattern: **personal-search leaders
do NOT rank by pure corpus relevance (BM25/ts_rank).** They (a) offer an explicit
relevance-vs-recency toggle, and (b) blend in *personal/social signals* — sender,
people-affinity, thread/channel, engagement — that weigh far more than raw text
match. Web search has nothing equivalent to these signals.

### 1.1 Slack — the most documented, and the template (Slack Engineering, 2017/2020)

Slack offers two explicit modes: **Recent** (reverse-chronological, "match all
terms") and **Relevant** (Lucene/Solr text score). Three findings matter:

**(a) Plain relevance LOST to plain recency.** Before personalization, "Relevant"
search was *used only ~17% of the time and performed slightly worse than Recent*
on clicks-per-search and top-position CTR. **In personal data, naive text
relevance is a worse default than reverse-chronological.** This is the empirical
counterpart to SIS §0.

**(b) The fix was personalization via the "work graph," not better text scoring.**
Slack trained a learning-to-rank model (SparkML SVM, pairwise transform on
in-session clicks). The signals it found **most significant**, verbatim:

- **The age of the message** (recency is a *top* learned feature, not a tie-break)
- The Lucene score of the message w.r.t. the query (text relevance — *one of
  many*, not the spine)
- **The searcher's _affinity_ to the author** ("propensity of that user to read
  the other's messages") — a *people* signal
- The **priority score of the searcher's DM channel** with the author
- The searcher's **priority score for the channel** the message appeared in
- **Whether the author == the searcher** (your own messages)
- **Whether the message was pinned, starred, or had emoji reactions** (engagement)
- The propensity of searchers to click on messages from that channel
- Content aspects: word count, line breaks, emoji, formatting

The headline reframe: *"aside from the Lucene 'match' score, we have not yet
incorporated any other semantic features of the message itself."* **The win came
almost entirely from people/thread/recency/engagement signals, not from text
relevance.** Result: +9% clicked searches, +27% clicks at position 1.

**(c) The product answer — show BOTH, don't make the user choose.** Slack's
shipped UX is **"Top Results"**: it runs Recent and Relevant *in parallel* on
every query, and surfaces the top ~3 personalized-relevant messages *above* the
normal recent list, gated by "simple heuristics, such as result diversity and
quantity." *"We wanted to make sure our users could find what they're looking for
… without having to worry about sorting by relevancy or recency."* This is the
single most transferable UX idea for PDPP (see §5).

### 1.2 Gmail — "Most relevant" default, explicit "Most recent" toggle (2025)

Gmail's March 2025 redesign is the clearest recent statement of the norm. It moved
the default *from* chronological *to* "Most relevant," whose three named signals
are, verbatim from Google's announcement:

- **Recency** — how recently the email arrived
- **Most-clicked emails** — emails you engage with/open most (engagement)
- **Frequent contacts** — senders you interact with regularly (people-affinity)

Note what's *absent* from the headline list: pure term-frequency text relevance.
The three named signals are **recency + engagement + sender relationship** — two
of three are personal/social, none is "BM25 over the body." And critically, Gmail
**keeps an explicit "Most recent" / "Latest" toggle** and *remembers the user's
last choice*. The product framing: *"Use Most relevant for digging through ongoing
projects or known senders; switch to Latest for time-sensitive or new inquiries."*
This is the relevance-vs-recency duality made a first-class UI control, with the
sender relationship as a top-three signal.

### 1.3 Notion — relevance blended with recency-of-edit + title-weighting

Notion's default "Best Matches" *blends* relevance and recency explicitly, and
adds a structural signal:

> "Pages that have been recently edited show up higher … and **page titles are
> more likely to show up than page contents**."

Two personal-data-specific signals: **recency-of-edit** (the document's *activity*,
not its arrival) and **title-over-body weighting** (in personal data, the title is
what the user *named* the thing — high recall value; cf. Teevan §2 on naming for
later recognition). Notion also exposes explicit overrides: *Last Edited
Newest/Oldest*, *Created Newest/Oldest*, and a *Title-only* filter. Same pattern:
smart blended default + explicit chronological/field overrides.

### 1.4 Apple Spotlight — "relevance + timeliness" + on-device usage signals

Spotlight's "Top Hit" is, per Apple, *"a combination of relevance and
timeliness"*, layered with **personal usage signals** (app-usage patterns,
engagement history) and, since WWDC 2024/2025, on-device ML + semantic ranking.
The personal-data-specific move: **usage/engagement is a ranking input** — apps
and items you use most are boosted; developers can *send engagement signals* to
improve an item's future rank. Again: relevance + recency + *personal engagement*,
not pure corpus relevance.

### 1.5 ChatGPT conversation search — known-item, title-weighted, exact-match

ChatGPT's own chat-history search (shipped late 2024, Cmd/Ctrl-K) is a pure
**known-item / re-finding** tool and its design admits it: it is *"primarily
title-based … searches conversation titles and some message content"*, **exact
matches**, *no* date-range or model filter. The tell is the *complement* it ships
alongside search: the sidebar **groups conversations by time bucket** (Today,
Yesterday, Previous 7 Days, Previous 30 Days, then by month). OpenAI's own guidance:
*"If you remember roughly when a conversation happened, this is often faster than
searching."* That is SIS §0 made into a UI — the product assumes the user has
*temporal memory* and gives them a time-bucketed browse as the primary re-finding
affordance, with keyword search as the secondary one. Title-weighting + time-bucket
browse is the canonical minimal personal-chat-search design.

### 1.6 Superhuman — speed-first, AND-default, local cache; ranking undisclosed

Superhuman's Cmd-K search is **AND-by-default** (all terms must match — the
known-item assumption: you remember specific words), supports quotes for exact
phrase and explicit `from:` / `has:attachment` operators, and is *"instant"* via a
**local cache of the inbox** (the latency lesson: personal-data search must feel
immediate because re-finding is interruptive). Its precise relevance-vs-recency
ranking formula is *not publicly disclosed* — recorded here as an honest negative
so a future reader doesn't hunt for a source that isn't public. The transferable
facts are the AND-default and the operator/field-search surface (people, has:),
both of which serve known-item intent (§2).

### 1.7 Microsoft 365 — "people-centric search" (the strongest people signal)

Microsoft Search's explicit thesis names the personal-data norm outright:

> "Typically when searching for something at work, users start their search using
> **people as guideposts** to find a specific e-mail, chat, or document. … they
> almost always know the people who worked on what they're looking for."

So M365 ships **people-centric search**: you pick a person, then search *within*
their content. Ranking draws on the Microsoft Graph "work graph" of collaboration
signals (frequent collaborators, org relationships, shared items). This is the
purest statement that **for personal data, the person/sender is often a stronger
retrieval key than the query terms** — you re-find *through people*.

### Cross-product synthesis

| Product | Default | Explicit recency mode | Personal/social signals beyond text |
|---|---|---|---|
| Slack | Top Results (personalized-relevant **+** recent shown together) | Yes ("Most recent") | Author affinity, channel priority, DM priority, self-authored, pinned/starred/reactions, **message age** |
| Gmail | Most relevant | Yes ("Most recent", remembered) | **Frequent contacts (sender)**, most-clicked (engagement), recency |
| Notion | Best Matches (relevance × **recency-of-edit**) | Yes (Last Edited / Created) | Recency-of-edit, **title-weighting** |
| Spotlight | Relevance + timeliness | (browse) | App/item **usage & engagement**, on-device ML |
| ChatGPT | Title + content keyword (exact) | Time-bucket **browse** | **Title-weighting**; time buckets |
| M365 | People-centric | — | **Person-as-primary-key**, work-graph collaboration |

**The convergent norm:** none of the six rank by pure corpus relevance. Every one
either (a) makes recency a co-equal/toggle-able axis (not a gentle tie-break), and
(b) blends in *who* (sender/author/people-affinity), *where* (thread/channel),
and *engagement* (pinned/clicked/edited) signals that **dominate** raw text match.
Web search has none of these; personal-data search lives or dies on them.

---

## 2. Known-item / re-finding intent — why personal data skews this way, and what serves it

### 2.1 The intent taxonomy and where personal data sits

The IR literature splits intent into **known-item search** (you have a *particular
item in mind* — "find THAT message") versus **exploratory search** (open-ended
learning/investigating an unfamiliar topic). Personal-data search is
overwhelmingly the former, and a specific sub-case of it: **re-finding** —
re-locating information *you have seen before*. The literature is explicit that
*"re-finding might be a special case of known-item searching."*

Re-finding is dominant and measurable:
- *33% of all search-engine queries have been issued before by the same user*
  (Teevan et al.).
- *40% of web searches are to re-find information the user has seen before.*
- *~55% of selections on messages in email clients are re-finding behaviors*
  (Elsweiler, Harvey & Hacker 2011).

So a personal-data search surface should be **optimized for known-item re-finding
first**, exploratory second — the inverse of a general web/discovery engine.

### 2.2 The cognitive model: recall (query) → recognition (scan) — and what it implies

The decisive design frame, from Teevan's "How People Recall, Recognize, and Reuse
Search Results" (ACM TOIS 2008): re-finding uses two memory processes —
**recall-directed search** (forming the query from what you remember) and
**recognition-based scanning** (skimming the result list and *recognizing* the
target). *"Recall corresponds to forming the query; recognition corresponds to
scanning the results."*

The ranking implications follow directly and are personal-data-specific:

1. **Rank on what the user can RECALL, because recall feeds the query.** Users
   recall, in rough order of reliability: **time** ("a couple weeks ago"),
   **person** ("from Sarah"), **thread/channel/context** ("in the deploys
   channel"), **a distinctive phrase**, and only weakly the full body text. So the
   highest-value ranking signals are **time, sender/people, thread/context,
   exact-phrase** — *not* corpus term frequency. This is exactly the signal set
   Slack/Gmail/M365 converged on (§1), and it is *why* they did.

2. **Optimize the list for RECOGNITION, because that's how the target is picked.**
   A recognition scan wants a result list the user can **navigate by their memory
   trace**. Two consequences: (a) **a date-ordered (or date-grouped) list is
   directly scannable** by temporal memory (SIS §0; ChatGPT's time buckets §1.5);
   (b) **snippets/titles/sender/timestamp must be shown** so recognition can fire
   on metadata, not just body text. Title-weighting (Notion, ChatGPT) helps
   because *people name things to recognize them later*: *"people pay careful
   attention when naming a file … for recognizing the file when it appears in a
   list of candidates."*

3. **Memory decays — so re-finding gets harder with age, which argues for
   exact-match precision over fuzzy recall.** A news re-finding study found *"a big
   drop in search performance … after a fortnight."* As the memory trace fades the
   user falls back on the few hard tokens they still hold (a name, an exact
   phrase, the approximate date). This is why personal-search products lean on
   **exact-match and AND-semantics** (ChatGPT "exact matches"; Superhuman AND
   default + quotes) and **field/operator search** (`from:`, `has:attachment`,
   date filters): known-item intent wants *precision* (find the one right thing),
   not the *recall*-maximizing OR/expansion that exploratory web search wants.

   > Note the tension with the companion note's ParadeDB/BM25 measurement, which
   > favored BM25's OR-semantics for *recall* and diversity. The reconciliation:
   > BM25 OR-recall helps the **exploratory** minority and the "I only remember
   > fuzzy words" case; AND/exact-precision helps the **known-item** majority.
   > A personal-data engine ideally supports *both* — AND/exact as the precise
   > default with an OR/expansion fallback when AND returns too few — rather than
   > picking one globally.

### 2.3 Ranking signals that specifically serve known-item re-finding

Synthesizing §1 + §2.2, the signal set a personal-data ranker should prioritize
(in rough order of known-item value), none of which appear in the companion
general-search note:

- **Recency / temporal proximity to a remembered time.** Not a tie-break — a
  primary navigable axis (SIS §0). Supports the "I know roughly when" memory.
- **Sender / author / people-affinity.** "From Sarah" is often the strongest
  recall token (Gmail frequent-contacts, Slack author-affinity, M365 person-key).
- **Thread / channel / conversation context.** "In the deploys channel"
  (Slack channel-priority). Personal data is *conversational*; the container is a
  recall key.
- **Exact phrase / quoted match.** A distinctive remembered phrase is high-signal;
  weight exact contiguous matches above scattered term hits.
- **Engagement / salience.** Pinned, starred, reacted, replied-to, frequently
  re-opened — items the user *acted on* are disproportionately re-find targets
  (Slack engagement signals, Spotlight usage, Gmail most-clicked).
- **Self-authored.** "Something I said" is a common re-find (Slack
  author==searcher).
- **Has-attachment / has-link / message type.** "The email *with the PDF*" — a
  structural recall key (Superhuman `has:attachment`, Gmail filters).

---

## 3. Relevance-first-with-recency-tiebreak, or recency-first-with-relevance-filter? What leaders actually do

This is the core question, and the honest answer is **neither extreme — and the
companion note's "relevance-primary, recency as gentle multiplier" general-search
default is too relevance-heavy for personal data.** What the leaders actually do:

**They reject the forced choice and present a date-navigable, relevance-surfaced
hybrid — with two explicit modes the user can pick.** Concretely:

1. **Recency is a co-equal primary axis, not a tie-break.** SIS found users
   *preferred* date order outright; Slack found plain recency *beat* plain
   relevance; Slack's learned model ranked **message age among its top features**;
   Gmail names recency as one of three headline signals; ChatGPT's primary
   re-finding affordance is a *time-bucketed list*. Treating recency as a mere
   `ORDER BY … emitted_at DESC` tie-break (the Algolia move the companion note
   landed on for general search) **under-weights it for personal data.** Personal
   data wants recency closer to a first-class sort key the user can lean on.

2. **But relevance-first chronological-second isn't right either** — because the
   known-item target is frequently *old* (the "ongoing project / known sender"
   case Gmail names), so a pure recency-first order buries it exactly as a pure
   relevance order buries the recent one. (This is literally the PDPP Slack bug
   from the companion note, but its mirror image: recency-first would bury the
   relevant-but-old answer.)

3. **So the shipped answer is "show both / let the user say which."** Two patterns,
   both worth adopting:
   - **Slack "Top Results":** run relevance and recency *in parallel*, show a small
     personalized-relevant cluster *above* a recent-ordered list. The user gets the
     few best-guess answers AND a chronological list to scan — no mode choice
     required. (Best when you can afford two queries and a sectioned UI.)
   - **Gmail / Notion / Spotlight toggle:** ship a *smart blended default*
     (relevance × recency × people, à la Gmail "Most relevant") **plus a
     first-class, remembered "Most recent" toggle.** The default serves the "I
     don't remember exactly when" case; the toggle serves the "I know it was
     yesterday / I want the latest" case. *Remembering* the choice matters
     (Gmail does).

**The SLVP-correct call for personal data (resolving the task's question):**
Neither "relevance-first-tiebreak" nor "recency-first-filter." Instead:

> **A blended default where recency and people/engagement are CO-EQUAL with text
> relevance (not subordinate to it), PLUS a first-class, explicit, remembered
> `sort=recency` mode.** Recency is promoted from tie-break to a weighted primary
> term; the explicit recency mode is non-negotiable (every leader ships it);
> and the ideal — bandwidth permitting — is Slack's "show both" so the user
> needn't pre-decide.

Note this *strengthens* the companion note's recommendation #2 (a `sort=recency`
mode), elevating it from "nice override" to **table stakes for personal data**,
and it *re-weights* the companion note's blend: where the general-search note
recommended a *gentle* multiplicative recency factor (`α≈0.3`) so it only reorders
near-ties, personal-data norms justify a **heavier recency weight** (and adding
people/engagement terms) because the user's temporal/social memory makes those
axes genuinely predictive of the target, not just decorative. Crucially, this also
*re-frames the live PDPP Slack bug*: it was diagnosed as "relevance-only ranking
buries recent matches under a dense old bulk-load." Through the personal-data lens
that is not a subtle tie-break gap — it is the **wrong default axis entirely** for
a personal corpus, exactly the failure SIS/Slack predicted for naive text
relevance over personal data.

---

## 4. Multi-signal ranking for personal data — beyond BM25 + recency

The companion note's blend is `bounded(ts_rank/BM25) × bounded(recency_decay)`.
For personal data that two-signal model is *insufficient* — the leaders all add a
**personal/social/structural** layer. The additional signal families, with their
source product and how they'd map onto PDPP's record model:

### 4.1 People signals (the highest-value addition)
- **Sender/author identity & affinity** — Gmail "frequent contacts," Slack
  author-affinity, M365 person-key. *Affinity* = how often the searcher interacts
  with this person (reads/replies). PDPP analog: records carry a sender/author
  field in many streams (Slack `user`, Gmail `from`, chat `role`); affinity is
  derivable from interaction frequency across the corpus. **Boost results from
  high-affinity people.**
- **Self-authored** — boost "things I said/wrote" (Slack author==searcher). PDPP
  analog: messages where the author is the data owner.
- **People-mentioned** — "the thread where Sarah was @-mentioned." A recall key
  even when Sarah isn't the sender.

### 4.2 Conversation/thread/container signals
- **Thread/channel grouping & priority** — Slack's channel-priority and
  DM-priority were *top learned features*. Two moves: (a) **boost** results in
  containers the user engages with; (b) **group/collapse** results by
  thread/conversation so a recognition scan sees one row per conversation, not 20
  near-duplicate messages (also directly mitigates the companion note's
  "density-domination / same message 10×" defect). PDPP analog: records already
  carry stream + a thread/conversation id in conversational connectors.

### 4.3 Engagement / salience signals
- **Pinned / starred / reacted / replied** — Slack found these significant;
  re-find targets are disproportionately items the user *acted on*. PDPP analog:
  reactions/stars exist in Slack-shaped records; replies/threading are derivable.
- **Re-open / click frequency** — Gmail "most-clicked," Spotlight usage. If PDPP
  ever logs which records a user/agent opens, that's a strong personalization
  signal (privacy-bounded).
- **Recency-of-edit/activity** (vs recency-of-arrival) — Notion ranks by *last
  edited*. For mutable records, "last touched" can beat "first created."

### 4.4 Structural / type signals
- **Title/subject over body** — Notion & ChatGPT both up-weight title matches;
  titles are named-for-recognition (Teevan §2.2). PDPP analog: weight matches in a
  record's title/subject/summary field above body text (Postgres `tsvector`
  weights `A`/`B`/`C`/`D` already support exactly this — assign the title field
  weight `A`, body `D`).
- **Has-attachment / has-link / message subtype** — "the email with the PDF"
  (Gmail/Superhuman filters). PDPP analog: structural facets on records.
- **Exact-phrase contiguity** — weight contiguous quoted matches above scattered
  term hits (Algolia "Proximity"/"Exact" criteria; ChatGPT/Superhuman exact-match
  default). Serves the distinctive-phrase recall token.

### 4.5 How leaders combine them: learning-to-rank over a two-stage retrieve+rerank
Slack's architecture is the template and is *directly portable* to PDPP's existing
two-layer shape (Postgres candidate fetch → JS merge/rank):

1. **Stage 1 (retrieve, cheap):** Solr/Postgres returns a candidate set ranked by
   *a few cheap features* (text score + a coarse recency/affinity proxy) — Slack
   used "the select few features that were easy for Solr to compute." This maps to
   PDPP's per-connector `postgresLexicalSearch` candidate fetch.
2. **Stage 2 (rerank, rich):** the application layer re-ranks candidates with the
   *full* feature set (people-affinity, channel-priority, engagement, message
   characteristics), weighted by a learned model (Slack used SparkML SVM with a
   pairwise transform on in-session clicks). This maps to PDPP's `roundRobinMerge`
   / snapshot layer — *the natural place to apply a multi-signal rerank.*

**For PDPP specifically (SLVP-pragmatic, not full ML):** PDPP almost certainly
lacks the click-log volume to train a learned reranker today. The SLVP move is a
**hand-tuned linear blend** of the cheaply-available signals, applied in the
existing merge layer:

```
score = w_rel · bounded_relevance        // BM25 (SQLite) / normalized ts_rank (PG)
      + w_rec · recency_decay             // exp/gauss over emitted_at — WEIGHTED, not tie-break
      + w_title · title_match_boost       // tsvector weight A on title/subject field
      + w_eng · engagement                // pinned/starred/reacted/replied if present
      + w_aff · sender_affinity           // interaction frequency with author (derivable)
      + w_self · self_authored            // owner == author
```

with title-weighting done *inside* the index (Postgres `setweight` / FTS5 column
weights) and the people/engagement/self terms applied in the JS merge layer where
the connector manifest and cross-stream context are already available. Start with
recency and title weighted *heavily* (the two cheapest, highest-value personal
signals), add people/engagement as the data supports them, and keep the explicit
`sort=recency` escape hatch (§3). This is a strict superset of the companion
note's `relevance × recency` blend — it just stops treating text relevance as the
spine and adds the personal-data signals the leaders proved matter most.

---

## 5. Top recommendations (the SLVP call for personal-data search)

Distilled, in priority order, calling out where this *changes* the companion
general-search note:

1. **Promote recency from tie-break to a weighted primary axis, AND ship an
   explicit, remembered `sort=recency` mode.** (Strengthens companion note's
   recommendation #2 from "nice override" to "table stakes.") Every personal-data
   leader does both; SIS/Slack proved naive text-relevance is a *worse* default
   than recency for personal data. Recency is the axis the user's episodic memory
   can navigate.

2. **Add the people/thread/engagement signal layer** (§4) — the thing that took
   Slack from "relevance loses to recency" to "+27% clicks at position 1." Minimum
   viable: **title-weighting** (Postgres `setweight A`, near-free) + **recency
   weighting** + **self-authored boost**. Ideal: **sender-affinity** and
   **engagement** (pinned/reacted/replied) terms in the merge layer. This is the
   single biggest quality lever and has *no analog in the general-search note*.

3. **Group/collapse by thread/conversation** in the result list (§4.2) — one row
   per conversation for the recognition scan. Doubles as the cleanest fix for the
   companion note's measured "density-domination / same message 10×" defect.

4. **Default to AND/exact precision, fall back to OR/expansion** (§2.2) — known-item
   re-finding wants precision; reserve BM25-style OR recall for the fuzzy-memory /
   exploratory minority. (Nuances the companion note's pro-BM25-recall finding:
   recall-maximizing is the *minority* intent for personal data.)

5. **Consider Slack "Top Results" UX** — run relevance and recency in parallel,
   show a small personalized-relevant cluster above a recent list. Removes the
   mode-choice burden entirely; best end-state if the two-query cost is acceptable.

6. **Treat the result list as a recognition surface** (§2.2) — always show
   sender + timestamp + thread + a snippet, and weight titles/subjects, so the
   user recognizes the target by metadata, not just body text. Time-bucket the
   list (ChatGPT pattern) when in recency mode.

The meta-point for PDPP: the companion note correctly solved *general* lexical
ranking (bounded relevance × recency, honest truncation). This note says that for
PDPP's actual workload — **search over the user's own messages/emails/chat** —
the *default* must shift: recency and people/engagement signals are co-equal-to-
or-stronger-than text relevance, an explicit recency mode is mandatory, and the
known-item/re-finding intent (not exploratory discovery) is what the whole surface
should be tuned for. That reframes the live Slack "buried recent matches" bug from
a tie-break nuance into a wrong-default-axis problem the personal-search
literature predicted three decades ago (SIS, 2003).

---

## References

Personal-data / PIM search products:
- Slack Engineering — "Search at Slack" (Recent vs Relevant; relevance lost to
  recency at 17% usage; learned reranker signals incl. **message age**, author
  affinity, channel/DM priority, self-authored, pinned/starred/reactions; two-stage
  retrieve+rerank; Top Results module): https://slack.engineering/search-at-slack/
- Slack — "Personalized Search: How It Works and Why It Matters" (work-graph,
  recent collaborators, recently-viewed, org/department trends):
  https://slack.com/blog/productivity/what-is-personalized-search-and-how-does-it-work
- Google — "Gmail's new search update finds relevant emails faster" (Most relevant
  = recency + most-clicked + frequent contacts; Most recent toggle, remembered):
  https://blog.google/products-and-platforms/products/gmail/gmail-search-update-relevant-emails/
- TechCrunch — Gmail relevance-over-chronological default + toggle:
  https://techcrunch.com/2025/03/20/gmails-new-ai-search-now-sorts-emails-by-relevance-instead-of-chronological-order/
- Notion — "Search in your workspace" (Best Matches = relevance × recency-of-edit,
  title > content; Last Edited / Created / Title-only overrides):
  https://www.notion.com/help/search
- Apple — Spotlight relevance + timeliness + usage signals; Core Spotlight ML/
  semantic ranking (WWDC24): https://developer.apple.com/videos/play/wwdc2024/10131/
  and Apple Support: https://support.apple.com/guide/iphone/search-on-iphone-iph3c511548/ios
- OpenAI — "How do I search my chat history in ChatGPT?" (title + content keyword,
  exact match, time-bucketed sidebar browse):
  https://help.openai.com/en/articles/10056348-how-do-i-search-my-chat-history-in-chatgpt
- Superhuman — Search (Cmd-K, AND default, quotes for exact, from:/has: operators,
  local cache): https://help.superhuman.com/hc/en-us/articles/46005672652301-Search
- Microsoft — People-centric search in Microsoft Search (people as guideposts;
  pick a person then search their content; Microsoft Graph work-graph signals):
  https://m365admin.handsontek.net/people-centric-search-in-microsoft-search/ and
  https://learn.microsoft.com/en-us/graph/social-intel-concept-overview

Personal-data search research (the academic backbone):
- Dumais et al., "Stuff I've Seen: A System for Personal Information Retrieval and
  Re-Use" (SIGIR 2003) — users **preferred date over relevance**; users leverage
  temporal memory of personal items. Surveyed in "Searching Personal Collections":
  https://arxiv.org/pdf/2412.12330
- Teevan, J., "How People Recall, Recognize, and Reuse Search Results" (ACM TOIS
  2008) — recall (query) vs recognition (scan); 33% of queries are repeats; naming
  for later recognition: https://people.csail.mit.edu/teevan/work/publications/papers/tois08.pdf
- Known-item search (vs exploratory; re-finding as a special case of known-item):
  https://en.wikipedia.org/wiki/Known-item_search and
  https://en.wikipedia.org/wiki/Exploratory_search
- Elsweiler, Harvey & Hacker — "Understanding re-finding behavior in naturalistic
  email interaction logs" (~55% of message selections are re-finding); Elsweiler,
  Baillie & Ruthven, "What Makes Re-finding Information Difficult? A Study of Email
  Re-finding" (ECIR 2011): https://strathprints.strath.ac.uk/32918/
- Whittaker et al. — email re-finding strategies; opportunistic search dominates
  foldering/tagging; preparatory foldering inefficient (BlueMail study).
- "Leveraging User Behavior History for Personalized Email Search" (per-user signal
  preferences vary; organizers prefer recency): https://arxiv.org/pdf/2102.07279
- "Searching Personal Collections" survey (catalogs SIS, the date-preference
  finding, and the PIM-search signal landscape): https://arxiv.org/pdf/2412.12330

Companion PDPP notes (general search; this note is the personal-data overlay):
- `docs/research/lexical-search-ranking-recency-prior-art-2026-06-15.md` —
  general relevance+recency blend (ES gauss, Algolia tie-break, Postgres
  normalization), honest truncation, ParadeDB/BM25 measurement.
- `docs/research/lexical-search-freshness-prior-art-2026-06-15.md` — index lag /
  freshness / self-healing watermark.
