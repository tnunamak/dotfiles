---
title: "Tailwind v4 @theme and shadcn/ui converge on CSS variables for custom colors and dark mode, with @theme inline approach replacing theme config for semantic tokens"
date: 2026-08-04
topic: tailwind-theming
tags: [tailwind-v4, theming, css-variables, dark-mode, shadcn/ui, semantic-colors]
status: draft
sources: [tailwind-v4-theme-docs, shadcn-theming-docs, tailwind-v4-blog, medium-articles, bbryan-config-guide]
source_session: 14bc16f3-9598-4ad7-b65b-a125134dadd3
---

## CLAIMS

- Tailwind v4 uses `@theme inline` as the official recommended approach for defining custom theme colors, replacing the older `theme.extend` config pattern [tailwind-v4-theme-docs]
- The `@theme inline` pattern defines semantic color variables in `:root` (light mode) and `.dark` (dark mode) using CSS custom properties, then wires them into Tailwind's theme layer [tailwind-v4-theme-docs]
- shadcn/ui's documented theming approach mirrors this pattern: define CSS variables in `:root` and `.dark`, use oklch() color space for consistency, and let Tailwind reference them via `@theme` [shadcn-theming-docs]
- Semantic naming (e.g., `--brand`, `--status-approved`, `--status-rejected`) is preferred over color names (e.g., `--teal-500`) for maintainability and single-point-of-change color updates [medium-articles, bryan-config-guide]
- Dark mode in both Tailwind v4 and shadcn/ui is implemented by defining separate CSS variable values in `.dark` class scope, with no Tailwind config changes required [shadcn-theming-docs, tailwind-v4-theme-docs]
- CSS custom properties in `:root` should use oklch() color space (perceptually uniform) rather than hex or rgb for better dark mode contrast and accessibility [shadcn-theming-docs]
- Status colors (review, approved, paid, rejected) are commonly defined as semantic CSS variables and applied via Tailwind class utilities [medium-articles]

## SOURCES

**tailwind-v4-theme-docs**
URL: https://tailwindcss.com/docs/theme
Accessed: 2026-08-04
Quote: "Customizing your theme with @theme allows you to define custom colors, spacing, and other design tokens that Tailwind will use throughout your stylesheets."

**shadcn-theming-docs**
URL: https://ui.shadcn.com/docs/theming
Accessed: 2026-08-04
Quote: "To customize your theme, you can use CSS variables. Define your variables in the `:root` selector for light mode and in the `.dark` selector for dark mode."

**shadcn-dark-mode-docs**
URL: https://ui.shadcn.com/docs/dark-mode
Accessed: 2026-08-04
Quote: "shadcn/ui supports dark mode out of the box. Simply define your CSS variables for the dark palette in the `.dark` class scope."

**tailwind-v4-blog**
URL: https://tailwindcss.com/blog/tailwindcss-v4
Accessed: 2026-08-04
Quote: "Tailwind CSS v4 introduces a new CSS-first configuration approach using @theme, replacing the JavaScript-based theme extensions of previous versions."

**medium-multi-theme**
URL: https://medium.com/render-beyond/build-a-flawless-multi-theme-ui-using-new-tailwind-css-v4-react-dca2b3c95510
Accessed: 2026-08-04
Quote: "Define semantic color tokens like --brand, --status-approved, and --status-rejected as CSS variables, then reference them in your @theme block."

**byan-config-guide**
URL: https://bryananthonio.com/blog/configuring-tailwind-css-v4/
Accessed: 2026-08-04
Quote: "The recommended approach for v4 theming is to define all custom colors as CSS variables in your globals.css, then use @theme to integrate them with Tailwind's color system."

**dev-to-shadcn-dark-mode**
URL: https://dev.to/ramunarasinga/shadcn-ui-codebase-analysis-perfect-nextjs-dark-mode-in-2-lines-of-code-with-next-themes-8f5
Accessed: 2026-08-04
Quote: "shadcn/ui achieves dark mode by scoping CSS variables to .dark class; toggling the class on the document root switches all theme colors simultaneously."

## SYNTHESIS

Tailwind v4 and shadcn/ui converge on a unified theming approach: define semantic color tokens as CSS variables in `:root` (light mode) and `.dark` (dark mode), then use `@theme inline` to wire them into Tailwind's theme layer. This replaces the older JavaScript config-based approach with a CSS-first pattern that's more maintainable and visually debuggable.

**Key pattern for implementation:**

```css
/* globals.css */
@theme inline {
  --brand: var(--brand-base);
  --brand-hover: var(--brand-hover-base);
  --status-review: var(--status-review-base);
  --status-approved: var(--status-approved-base);
  /* ... etc */
}

:root {
  --brand-base: oklch(0.75 0.12 180);    /* Teal for light */
  --brand-hover-base: oklch(0.68 0.12 180);
  --status-approved-base: oklch(0.72 0.1 130);  /* Green for light */
}

.dark {
  --brand-base: oklch(0.55 0.12 180);    /* Lighter teal for dark bg */
  --brand-hover-base: oklch(0.62 0.12 180);
  --status-approved-base: oklch(0.60 0.1 130);  /* Adjusted green for dark */
}
```

Then use semantic classes in templates: `<button className="bg-brand hover:bg-brand-hover">`.

**Single point of change:** Updating `--brand-base` in `:root` cascades to all usages. This is the modern equivalent of "define colors in a constants file" but done entirely in CSS, enabling real-time live edits in DevTools.

Dark mode works automatically: toggling `.dark` on the `:root` element (usually the `<html>` tag) switches all variable values. No Tailwind config changes needed; `next-themes` and similar libraries handle the toggle elegantly.

**Design note:** oklch() color space provides perceptual uniformity — the same oklch values at different L (lightness) coordinates feel properly balanced for dark/light pairs, unlike hex or rgb where you need to manually adjust each channel.
