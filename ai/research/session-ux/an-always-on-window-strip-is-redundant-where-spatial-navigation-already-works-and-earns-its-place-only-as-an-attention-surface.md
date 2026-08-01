---
title: "An always-on window strip is redundant where stable spatial navigation already works; on a spatial surface it earns its place only as an attention/state indicator, not a switcher"
date: 2026-07-16
topic: session-ux
tags: [status-line, spatial-nav, workspaces, activities, tab-overload, attention, tmux]
status: draft
sources: [i3-userguide, gnome-workspaces, kde-kactivities, chang-chi2021, cmu-tab-overload, groupbar-ozchi2003b]
source_session: 66850dc0-bec5-47ac-9554-487d12bfb62b
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = interpretation. Skippable. No citations here.
-->

## CLAIMS

- i3 supports named workspaces (a number plus a name prefix) and its user guide states a common paradigm of putting the web browser on one workspace, communication apps on another, and work on a third — one workspace per role/task. [i3-userguide]
- i3's `assign` binds an application matched by window criteria to a specific workspace, so a given app reliably appears in the same spatial location. [i3-userguide]
- GNOME frames workspaces explicitly as grouping windows by task (e.g. all communication windows on one workspace, current work on another). [gnome-workspaces]
- KDE Activities represent the "what are you doing" contextual axis — a task context that may span multiple applications and share applications across contexts — and are complementary to virtual desktops, which are the spatial "where a window lives" axis. [kde-kactivities]
- In a CMU study, users kept browser tabs open past the point of being unmanageable because of a "blackhole effect": they feared that once something went out of sight it was gone, and they felt invested in open tabs even when overwhelmed. [chang-chi2021] [cmu-tab-overload]
- About 25% of participants in one aspect of the CMU tab study reported their browser or computer crashed from having too many tabs open. [cmu-tab-overload]
- Any bar interface eventually runs out of horizontal space as window count grows, forcing paging or shrinking that makes many relevant items hard to access. [groupbar-ozchi2003b]

## SOURCES

**i3-userguide**
URL: https://i3wm.org/docs/userguide.html
Accessed: 2026-07-16
Quote: "A common paradigm is to put the web browser on one workspace, communication applications (mutt, irssi, …) on another one, and the ones with which you work, on the third one." / "To automatically make a specific window show up on a specific workspace, you can use an assignment. You can match windows by using any criteria." / "If you want the workspace to have a number and a name, just prefix the number".

**gnome-workspaces**
URL: https://help.gnome.org/users/gnome-help/stable/shell-workspaces.html.en
Accessed: 2026-07-16
Quote: "Workspaces can be used to organize your work. For example, you could have all your communication windows, such as e-mail and your chat program, on one workspace, and the work you are doing on a different workspace."

**kde-kactivities**
URL: https://invent.kde.org/plasma/kactivitymanagerd
Accessed: 2026-07-16
Quote: "there are three main areas of contextual information ... who the user is, where they are, and what they are doing. Activities deal with the last one. An activity might be 'developing a KDE application' ... Each of these activites may involve multiple applications, and a single application may be used in multiple activities".

**chang-chi2021**
URL: https://dl.acm.org/doi/fullHtml/10.1145/3411764.3445585
Accessed: 2026-07-16
Quote: (ACM open-access HTML; automated fetch returns 403, readable in-browser. Qualitative findings corroborated via cmu-tab-overload below.) Title: "When the Tab Comes Due: Challenges in the Cost Structure of Browser Tab Usage," CHI 2021.

**cmu-tab-overload**
URL: https://www.cmu.edu/news/stories/archives/2021/may/overcoming-tab-overload.html
Accessed: 2026-07-16
Quote: "People feared that as soon as something went out of sight, it was gone." / "Fear of this blackhole effect was so strong that it compelled people to keep tabs open even as the number became unmanageable." / "About 25% of the participants in one aspect of the study reported that their browser or computer crashed because they had too many tabs open."

**groupbar-ozchi2003b**
URL: https://www.microsoft.com/en-us/research/wp-content/uploads/2003/01/ozchi2003-groupbar.pdf
Accessed: 2026-07-16
Quote: "As the number of displayed windows increases, any type of bar interface will eventually run out of space."

## SYNTHESIS

**On desktop, the always-on strip does not earn its place as a switcher — and the evidence says so.** Tim's 18 kitty portholes parked on fixed tmux windows are a spatial switcher in the Data Mountain / SCOTZ sense (see the switching-ordering entry): retrieval is by muscle memory to a stable location, no visual search of a list. A strip that re-lists those same windows is redundant with the spatial map and, per GroupBar, a bar cannot even fit ~27 items without shrinking or paging into illegibility. Tim's own read that "the strip is mostly noise there" is the correct one; the literature backs removing or radically demoting it on the spatial surface.

**Where the strip (or a sidecar) does earn its place is as an attention surface, not a navigator.** The one thing spatial nav can't give you is "which of the windows I'm NOT looking at needs me now." The tab-overload research shows the real cost of many contexts is the blackhole effect — things going out of sight feel lost — and the antidote is not a fuller list but a signal that surfaces the few contexts changing state (agent needs input, job finished, error). So on desktop, replace the always-on window list with a compact attention indicator: a count/glyph of windows-needing-input, expandable on demand. This is an indicator, not a switcher — the switcher is the spatial map plus the on-demand picker.

**Workspace conventions support per-role spatial assignment, not a global flat strip.** i3/GNOME/KDE all converge on grouping contexts by task/role into stable spatial locations (i3 `assign`, GNOME per-task workspaces, KDE Activities as the "what are you doing" axis distinct from spatial desktops). The lesson for the 4-virtual-desktop layout: assign window classes/projects to stable desktops+portholes so the spatial map is deterministic, and reserve any always-on chrome for the task-context label + attention state, not an enumeration of windows.

**Mobile is the inverse case and flips the conclusion.** On mobile there is no spatial map — no portholes, no muscle memory — so the strip/picker is the ONLY nav and its job is genuinely switching. There the answer is the vertical searchable picker (see the touch-picker entry), not a compact attention glyph. The design should therefore be surface-aware: desktop demotes the strip to an attention indicator (spatial map carries switching); mobile promotes a full vertical searchable picker (no spatial map to lean on). One label/state model, two renderings.
