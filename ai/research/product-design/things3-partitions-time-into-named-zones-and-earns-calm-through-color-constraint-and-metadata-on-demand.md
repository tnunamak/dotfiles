---
title: "Things 3 partitions time into named zones (present primary, future explicitly separated), keeps rows to glyph + title with metadata on demand, and earns calm through color constraint rather than color elimination"
date: 2026-06-23
topic: product-design
tags: [chronology, temporal-zones, list-design, visual-calm, animation, mobile, things3]
status: draft
sources: [cc-home, cc-features, cc-whats-new, cc-os26, cc-support-today, cc-support-scheduling, macstories-things3, masalar-things3, pratt-critique, block81-things3, calmevo-things3, smith-things3, greypatterson-things3]
---

## CLAIMS

- Things 3 partitions tasks into four named temporal zones — Today (start date is today; includes a "This Evening" subsection), Upcoming (future start date, hibernating until the date arrives, forward-chronological), Anytime (no start date), Someday (explicitly deferred) — that encode a contract about what the user can act on now. [cc-support-today]
- Future-dated items literally disappear from all action-oriented views (Today, Anytime) and live only in Upcoming, so the user never sees a future item mixed into present-day work; when the start date arrives the task automatically appears in Today. [cc-support-today] [cc-support-scheduling]
- Upcoming shows the next 7 days individually under per-day headers ("Tomorrow", then "[Weekday], [Month Day]"), then buckets further-out items week-by-week and month-by-month to give "a bird's-eye view of tasks further out in the future"; the whole list is strictly forward-chronological. [cc-support-today] [cc-support-scheduling]
- Upcoming is a separate navigation destination reached from the sidebar, not a collapsed section within Today — a stronger separation than an in-page section. [cc-support-today]
- Things offers exactly one sub-day granularity ("This Evening"), a deliberate single binary split (Now vs This Evening) chosen to prevent over-scheduling anxiety; it does not offer morning/afternoon/evening/night slots. [cc-support-today]
- Empty days in Upcoming still show their day header so the full weekly structure is visible at a glance even when some days have no tasks. [cc-support-scheduling]
- Things uses the system font (SF Pro) exclusively at effectively three sizes (large section/view titles, medium task titles, small metadata), doing hierarchical work through weight contrast rather than color; section headers are heavier than task titles, metadata is lighter/smaller. [macstories-things3] [pratt-critique]
- The collapsed task row shows only a round checkbox (not a square) and the task title, with at most one accessory (a deadline dot/flag if urgent); notes, tags, date, and deadline chips appear only in the expanded/detail state below the title at smaller, lighter scale. [pratt-critique]
- Task rows have no background color, no alternating tints, and no status-color-coded backgrounds; color is reserved for sidebar area/project icons (teal, orange, purple, green), the interactive completion accent (Things' iconic blue), and deadline indicators — the restraint is what makes the list feel calm. [macstories-things3] [greypatterson-things3]
- Things task rows show no created-at/modified-at timestamps; temporal anchoring happens at the section/day-header level, not the row level. [pratt-critique]
- Tapping a task row expands it in place (grows downward) to reveal detail fields rather than navigating to a new screen, preserving list context; on Mac/iPhone the task detail rises as a card-like sheet. [macstories-things3] [pratt-critique]
- The "Magic Plus" is a floating action button that on tap creates a to-do at the bottom of the list and on long-press-and-drag becomes draggable, showing insertion-point indicators between rows/sections and encoding semantic intent by direction (drag to the left margin in a project creates a heading, drag to the Inbox sidebar target creates an Inbox item) — direct manipulation replacing insert-above/below menus. [cc-features] [macstories-things3]
- Cultured Code built a custom animation toolkit (not stock UIKit) so every state change (completion, drag, section transition, list-to-detail) is animated with short, purposeful durations; there are no ambient/idle animations, and task completion triggers a haptic pulse on iPhone. [cc-features] [macstories-things3]
- On iPhone the app shows one list at a time (no split pane, no bottom sheets); section headers span full width as left-aligned larger text, and Things does not use swipe-to-complete on the main list (the tap-the-circle paradigm is primary, avoiding accidental completions while scrolling). [pratt-critique] [block81-things3]
- The 2025/2026 OS 26 refresh deliberately increased spacing ("wider spacing that feels a bit more relaxed") and added "a touch of glass in the sidebar" while keeping the list content area clean and flat with no card shadows on individual rows. [cc-os26]
- Separators appear only at section boundaries (hairline-thin or spacing-only), never between individual rows within a section; section headers carry substantial top padding as the visual gutter. [macstories-things3] [pratt-critique]
- Things 3 won two Apple Design Awards and is described by reviewers as one of the most tactile, fast-as-you-can-move apps and among the most beautiful Mac/iOS apps. [macstories-things3] [masalar-things3]

## SOURCES

**cc-home**
URL: https://culturedcode.com/things/
Accessed: 2026-06-23

**cc-features**
URL: https://culturedcode.com/things/features/
Accessed: 2026-06-23
Quote: "Beautiful animations. Everything you do in Things is nicely animated for pop. This is achieved with our own, custom-built animation toolkit."

**cc-whats-new**
URL: https://culturedcode.com/things/whats-new/
Accessed: 2026-06-23

**cc-os26**
URL: https://culturedcode.com/things/blog/2025/09/things-for-os-26/
Accessed: 2026-06-23
Quote: "wider spacing that feels a bit more relaxed"

**cc-support-today**
URL: https://culturedcode.com/things/support/articles/4001304/
Accessed: 2026-06-23
Quote: "An In-Depth Look at Today, Upcoming, Anytime, and Someday."

**cc-support-scheduling**
URL: https://culturedcode.com/things/support/articles/2803579/
Accessed: 2026-06-23
Quote: "Scheduling To-Dos in Things."

**macstories-things3**
URL: https://www.macstories.net/reviews/things-3-beauty-and-delight-in-a-task-manager/
Accessed: 2026-06-23
Quote: "each interface gesture invokes subtle, deeply satisfying animations."

**masalar-things3**
URL: https://mariusmasalar.me/things-3-first-impressions-8f0155c60cf2
Accessed: 2026-06-23

**pratt-critique**
URL: https://ixd.prattsi.org/2020/02/design-critique-things-3-ios-app/
Accessed: 2026-06-23

**block81-things3**
URL: https://block81.com/blog/organizing-my-life-with-things-3
Accessed: 2026-06-23

**calmevo-things3**
URL: https://calmevo.com/things-3-review/
Accessed: 2026-06-23

**smith-things3**
URL: https://medium.com/@smithtimmytim/review-things-3-for-mac-and-ios-114f4420f44b
Accessed: 2026-06-23

**greypatterson-things3**
URL: https://greypatterson.me/2017/06/things-3/
Accessed: 2026-06-23

## SYNTHESIS

Things 3 is the best prior art for a chronological list that separates present from future. Its radical bet — the present is primary, the future is explicitly separated, the past is out of the action views — solves the "future items burying the present" problem by making future-dated items hibernate entirely out of Today and appear only in a distinct Upcoming destination that is forward-chronological, with 7-day granular headers collapsing into week/month buckets further out. The single sub-day split ("This Evening") and the show-headers-for-empty-days rule are both deliberate restraint choices that keep the temporal skeleton legible without over-segmenting.

On craft, the transferable rules are: lead every row with a consistent fixed-width left glyph (Things' round checkbox) so the eye scans a predictable left column; show only glyph + title + at most one urgency indicator on the collapsed row and reveal everything else on expand-in-place (never navigate away for simple viewing); no row-background tinting — color lives in icons and one interactive accent, not in the data rows; system font at three sizes with weight (not color) as the hierarchy signal; section headers styled as document headings with generous top padding and no inter-row separators; and a small set of named, short, purposeful animation tokens (plus haptics on mobile) instead of generic CSS transitions. The header-label format progression (Today / Yesterday / [Weekday], [Month Day] / week buckets / month / year) is a clean template for any multi-scale chronological feed.
