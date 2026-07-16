---
title: "Switching among many live contexts is fastest with stable spatial position plus pinned hot slots, with fuzzy search for the long tail and MRU reserved for the last-1-2 toggle — no single ordering wins"
date: 2026-07-16
topic: session-ux
tags: [window-switching, mru, spatial-memory, harpoon, command-palette, information-foraging, tmux]
status: draft
sources: [tak-interact2011, groupbar-ozchi2003, alttab-wikipedia, data-mountain-uist1998, scalable-fabric-avi2004, vscode-ui, jetbrains-recent-files, harpoon-readme]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = interpretation. Skippable. No citations here.
-->

## CLAIMS

- People have more than eight windows open almost 80% of the time and switch windows on average every 20.9 seconds. [tak-interact2011]
- Window revisitation follows an inverse-exponential distribution: 80% of window switches involve only 35% of windows — the hot set is small and skewed. [tak-interact2011]
- Two documented failures of current window switchers are (1) lack of spatial stability, forcing slow visual search instead of rapid spatial decisions, and (2) weak support for revisitation patterns. [tak-interact2011]
- Recency / z-order ordering (as used by Windows Alt+Tab) is spatially unstable: the position of a window's representation changes from switch to switch as the z-order changes, and it is unclear how well users can anticipate z-order. [tak-interact2011]
- In a controlled study, mean window-switch times were 1.1 s (taskbar button), 1.2 s (SCOTZ, a spatially stable thumbnail switcher), 2.1 s (taskbar thumbnail), and 2.1 s (Alt+Tab); the spatially stable switcher tied the fastest tool and beat MRU Alt+Tab. [tak-interact2011]
- Alt+Tab was ranked least preferred by 75% of participants and judged more mentally demanding and more effortful than the Windows taskbar. [tak-interact2011]
- Windows Alt+Tab orders windows by most-recently-used, so repeated Alt+Tab keystrokes switch between the two most recent tasks — MRU is optimized for the last-1-2 toggle. [alttab-wikipedia]
- Any flat bar interface eventually runs out of horizontal space as the number of windows grows; the original Windows taskbar coped by paging tiles behind small arrow handles, which makes many relevant tiles hard to access. [groupbar-ozchi2003]
- In a comparative study, participants multitasked faster using GroupBar (spatial grouping) than the flat Windows taskbar. [groupbar-ozchi2003]
- A stable spatial layout (Data Mountain) had statistically reliable advantages over a flat titled list (Internet Explorer Favorites) for document retrieval: participants were reliably faster and made reliably fewer incorrect retrievals. [data-mountain-uist1998]
- Spatial memory in the physical world lets people remember approximately where they placed something for a long time; a virtual spatial layout can exploit the same durable mental map. [data-mountain-uist1998]
- As displays grow, users leave more windows open for multitasking, which increases time spent arranging and switching between tasks; spatial arrangement of tasks leverages human spatial memory to make switching easier. [scalable-fabric-avi2004]
- A command palette (VS Code Shift+Cmd+P) is a single fuzzy-search entry point to all functionality; Quick Open (Cmd+P) navigates to any file by typing its name, and repeatedly pressing Cmd+P cycles through recently opened files — i.e. the palette layers an MRU fallback on top of fuzzy search. [vscode-ui]
- JetBrains Recent Files (Ctrl+E) is recency-ordered over all recently opened/edited files (not just open tabs) and supports type-to-filter fuzzy search that narrows results dynamically. [jetbrains-recent-files]
- Neovim Harpoon's stated rationale is that for a small set of frequently-visited files, a fuzzy finder is tiring and `:bnext`/`:bprev` recency-cycling is too repetitive; the fix is manual pinning reachable with a single key. [harpoon-readme]
- Harpoon explicitly generalizes its "reach with a single key" model to persistent terminals and tmux windows, not just files. [harpoon-readme]

## SOURCES

**tak-interact2011**
URL: https://dl.ifip.org/db/conf/interact/interact2011-1/TakSGC11.pdf
Accessed: 2026-07-16
Quote: "Previous work has found that people have more than eight windows open almost 80% of the time and that the average time between window switches is only 20.9 seconds" / "window switching follows an inverse exponential distribution, with 80% of window switches involving only 35% of windows." / "Z-ordering is similar to recency ordering, but sorting windows by z-order is spatially unstable: the ordering of the window representations will be different from switch to switch if the z-ordering of the windows changes. Also, it is unclear how well users understand and can anticipate z-order." / "Mean window switching times when using a Taskbar button, a Taskbar thumbnail, Alt+Tab and SCOTZ are 1.1s, 2.1s, 2.1s and 1.2s, respectively, giving a significant effect of interface: (F3,33=53.3, p<.001)." / "Alt+Tab was unpopular, with 75% of participants ranking it as least preferred. Alt+Tab was also judged to be more mentally demanding and costing more effort than the Windows Taskbar."

**groupbar-ozchi2003**
URL: https://www.microsoft.com/en-us/research/wp-content/uploads/2003/01/ozchi2003-groupbar.pdf
Accessed: 2026-07-16
Quote: "As the number of displayed windows increases, any type of bar interface will eventually run out of space. The original Windows TaskBar deals with the issue by making users page through sets of tiles using small arrow handles... this approach makes a large number of potentially relevant tiles difficult to access" / "participants were able to multitask faster when using GroupBar than when using the existing Windows TaskBar."

**alttab-wikipedia**
URL: https://en.wikipedia.org/wiki/Alt-Tab
Accessed: 2026-07-16
Quote: "Alt+Tab orders windows by most recently used; thus, repeated Alt+Tab keystrokes will switch between the two most recent tasks."

**data-mountain-uist1998**
URL: https://www.microsoft.com/en-us/research/wp-content/uploads/1998/01/p153-robertson.pdf
Accessed: 2026-07-16
Quote: "Our study shows that the Data Mountain has statistically reliable advantages over the Microsoft Internet Explorer Favorites mechanism for managing documents of interest in an information workspace." / "Participants were reliably faster, on average, using the Data Mountain, especially in the thumbnail and All cueing conditions." / "when we place a piece of paper on a pile in our office, we are likely to remember approximately where that paper is for a long time."

**scalable-fabric-avi2004**
URL: https://www.microsoft.com/en-us/research/wp-content/uploads/2004/01/avi2004-scalablefabric.pdf
Accessed: 2026-07-16
Quote: "as displays become larger, users leave more windows open for easy multitasking. A larger number of windows, however, may increase the time that users spend arranging and switching between tasks." / "The spatial arrangement of tasks leverages human spatial memory to make task switching easier."

**vscode-ui**
URL: https://code.visualstudio.com/docs/getstarted/userinterface
Accessed: 2026-07-16
Quote: "The most important key combination to know is ⇧⌘P ... which brings up the Command Palette. From here, you have access to all functionality within VS Code" / "⌘P ... enables you to navigate to any file or symbol by typing its name". (Quick Open MRU-cycling behavior corroborated at https://code.visualstudio.com/docs/getstarted/tips-and-tricks.)

**jetbrains-recent-files**
URL: https://www.jetbrains.com/help/idea/recent-files-and-changes.html
Accessed: 2026-07-16
Quote: "You can search for recently opened or edited files using the Recent Files popup." / "To open the Recent Files popup, press Ctrl+E." / "To search for items within the popup, start typing your search query. IntelliJ IDEA filters the results dynamically as you type, showing only the matching items."

**harpoon-readme**
URL: https://github.com/ThePrimeagen/harpoon/blob/harpoon2/README.md
Accessed: 2026-07-16
Quote: "You find yourself frequenting a small set of files and you are tired of using a fuzzy finder, `:bnext` & `:bprev` are getting too repetitive, alternate file doesn't quite cut it, etc etc." / "have any number of persistent terminals that can be easily navigated to, send commands to other tmux windows, or dream up your own custom action and execute with a single key."

## SYNTHESIS

The literature converges and the strategies are complementary, not competing — which answers "search-first vs recency-first vs attention-first" as "all three, scoped to what each is good at."

- **Recency/MRU is a two-item tool.** Alt+Tab's own design (toggle the two most recent) is where MRU shines, and every study that put MRU against a stable layout at scale found it slower and less liked (2.1 s vs 1.1–1.2 s; least-preferred by 75%). MRU is spatially unstable by construction — the thing you reach for moves every time. Reserve it for "flip back to the previous window," nothing more.

- **Stable spatial position is the retrieval win, and Tim already exploits it.** Data Mountain and SCOTZ both prove that a fixed position lets the user build a durable mental map and reach without visual search. Tim's 18 kitty portholes parked on fixed tmux windows ARE a spatial switcher — that is why the strip is noise on desktop. Do not disturb this; the redesign should protect spatial constancy, not add motion to it.

- **The hot set is small and skewed (80/35), which is the empirical license for pinned hot slots.** Harpoon names the exact gap: for the handful of contexts you return to constantly, a fuzzy finder is tiring and recency-cycling is repetitive; a few stable, ordinally-keyed slots beat both. This maps directly onto Tim's ~12 porthole-less windows: give the hottest of them fixed ordinal keys (a Harpoon layer over tmux windows) so they get spatial-style constancy without needing a dedicated kitty porthole. Pinned slots should exist ALONGSIDE search, not instead of it.

- **Fuzzy search is the long-tail tool.** VS Code and JetBrains both make a palette the entry point for "any of everything," and both bolt MRU-cycling on top precisely because fuzzy search alone handles the return-to-recent case poorly. For the ~12 windows reached only via picker/strip (the cold tail), a fuzzy popup (tmux-fzf / sessionx already installed) is the right default — recall-based search scales where a flat list does not.

Design recommendation: the picker should be **search-first for the cold tail, with pinned ordinal hot slots as a parallel fast path, and MRU used only for a dedicated last-toggle key** — not one global ordering. Attention/state (needs-input) belongs as a sort key or badge WITHIN the search results, not as the primary ordering, because a re-sorting list re-breaks the spatial stability that makes the picker learnable.
