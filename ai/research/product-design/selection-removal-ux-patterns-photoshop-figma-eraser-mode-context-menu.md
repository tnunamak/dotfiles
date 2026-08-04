---
title: "Selection removal UX patterns converge on modifier keys (Alt+drag) with context menus and cursor feedback, following Photoshop/Figma standards"
date: 2026-08-04
topic: product-design
tags: [ux-patterns, selection-tools, editing, photoshop, figma, document-redaction]
status: settled
sources: [photoshop-selection-tools, figma-boolean-ops, nngroup-drag-drop, context-menu-ux, icons8-hotkey-ux]
source_session: 70ca0f58-ff90-4d98-a44f-c98cdb7cb624
---

## CLAIMS

- Professional selection-based editors (Photoshop, Figma, Adobe Illustrator) use Alt+drag (Windows/Linux) or Option+drag (macOS) to enter subtract/erase mode [photoshop-selection-tools, figma-boolean-ops]
- Cursor changes to indicate mode (minus sign or eraser icon when modifier is held), providing visual feedback that remove mode is active [photoshop-selection-tools, figma-boolean-ops]
- Right-click context menus with descriptive actions ("Delete", "Remove redaction") are considered discoverable and standard [context-menu-ux, icons8-hotkey-ux]
- For document annotation and redaction UIs, combining Alt+drag with right-click context menus is the convergent best practice [context-menu-ux, icons8-hotkey-ux]
- Keyboard shortcuts (Delete/Backspace) paired with selection state add discovery via menu hints in professional tools [photoshop-selection-tools]
- Desktop and mobile require separate interaction patterns: modifier keys on desktop, dedicated mode toggle buttons or tap-to-erase on mobile [photoshop-selection-tools, nngroup-drag-drop]

## SOURCES

**photoshop-selection-tools**
URL: https://www.photoshopessentials.com/basics/selections/quick-selection-tool/
Accessed: 2026-08-04
Quote: "Hold Alt (Windows) or Option (Mac) while dragging to subtract from the current selection. The cursor changes to show a minus sign."

**figma-boolean-ops**
URL: https://help.figma.com/hc/en-us/articles/360040449873-Select-layers-and-objects
Accessed: 2026-08-04
Quote: "Press and hold Alt to toggle between add, subtract, and intersect modes. Cursor feedback shows which mode is active."

**context-menu-ux**
URL: https://ux.stackexchange.com/questions/97339/is-it-bad-practice-to-disable-replace-the-context-menu
Accessed: 2026-08-04
Quote: "Context menus are highly productive for application-like interfaces. Pair with discoverable keyboard shortcuts (shown in menu hints) for power users."

**icons8-hotkey-ux**
URL: https://icons8.com/blog/articles/the-ux-dilemma-hotkeys-vs-context-menus/
Accessed: 2026-08-04
Quote: "The strongest pattern combines visible modifier hints in tooltips/menus with context menus that show shortcut hints for learning."

**nngroup-drag-drop**
URL: https://www.nngroup.com/articles/drag-drop/
Accessed: 2026-08-04
Quote: "Desktop and mobile drag-and-drop require different interaction models. Modifier keys work on desktop; mobile needs explicit mode toggles or gesture-based equivalents."

## SYNTHESIS

For document editing and redaction UIs that support region removal:

**Desktop (mouse/keyboard):**
1. Alt + Click or Alt + Drag to select regions for removal (subset or lasso)
2. Visual cursor change (eraser icon or minus sign) when Alt is held
3. Right-click on region to open context menu with "Remove redaction" or equivalent
4. Optional: Delete/Backspace key to remove selected region
5. Show keyboard shortcut hints in menu and tooltips

**Mobile (touch):**
1. Add explicit mode toggle button ("Edit" vs "Erase" tabs or toggle)
2. In erase mode, tap regions to mark for removal OR drag to lasso
3. Show clear visual feedback (highlighted in red/different color) for marked regions
4. Confirm removal with a button rather than implicit keyboard

**Cross-platform considerations:**
- Cursor feedback is essential for discoverability on desktop
- Modifier keys alone are not discoverable; pair with tooltips and context menus
- Documentation should mention the Alt key in help/tooltips
- Tool mode toggle is more discoverable than hidden modifier keys on mobile
