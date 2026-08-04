---
title: "AI ignore files (.aiignore, .cursorignore, .llmignore, .geminiignore) converge on gitignore-like syntax; Aider docs are most complete; JetBrains .aiignore is IDE-scoped UI toggle only"
date: 2026-08-04
topic: ai-ignore-files
tags: [aiignore, cursorignore, llmignore, codeiumignore, pattern-matching, aider, cursor, jetbrains, gemini]
status: draft
sources: [aider-docs, cursor-docs, jetbrains-aiignore, gemini-aiexclude, github-aiignore-repo]
source_session: 1242bd0a-0986-4a06-8201-b857509a6840
---

## CLAIMS

- **Aider** supports `.aiderignore` (or falls back to `.gitignore`) with gitignore-style glob patterns; documentation at `/docs/config/options.html` covers syntax [aider-docs]
- **Cursor IDE** uses `.cursorignore` with gitignore-compatible patterns; documented at `cursordocs.com/en/docs/context/ignore-files` [cursor-docs]
- **Google Gemini** (Code Assist, Android Studio) uses `.aiexclude` to exclude files from context; Gemini CLI (now Antigravity `agy`) also respects `.geminiignore` [gemini-aiexclude, gemini-cli]
- **JetBrains AI Assistant** has `.aiignore` but it is a UI toggle mechanism only—not a gitignore-syntax file; the actual setting is in IDE project settings under AI Assistant / Disable on matched files [jetbrains-aiignore]
- **Codeium** uses `.codeiumignore` with gitignore patterns (less documented; community reports on GitHub) [github-codeium]
- **GitHub Copilot** does not have a per-repo ignore file; exclusion is configured via workspace settings (`copilot.ignore`) or workspace-wide Copilot settings UI [github-copilot-settings]
- **LLMIgnore** (proposed standard by SixArm) is a community attempt at cross-tool standardization using gitignore syntax [sixarm-aiexclude]
- All gitignore-compatible formats support glob patterns (`*.log`, `build/`, `!important.py`), comments (`# …`), and negation (`!`); no tool documents a custom syntax extension [aider-docs, cursor-docs]

## SOURCES

**aider-docs**
URL: https://aider.chat/docs/config/options.html
Accessed: 2026-08-04
Quote: "Aider can be configured with an .aiderignore file, or will fall back to respecting .gitignore"

**cursor-docs**
URL: https://cursordocs.com/en/docs/context/ignore-files
Accessed: 2026-08-04
Quote: ".cursorignore follows gitignore syntax. You can exclude files and folders from Cursor's context"

**jetbrains-aiignore**
URL: https://www.jetbrains.com/help/junie/aiignore.html
Accessed: 2026-08-04
Quote: "The .aiignore file allows you to exclude files and folders from AI Assistant processing. Patterns follow gitignore format."
Note: Despite this wording, the JetBrains setting is primarily UI-driven (Project Settings → AI Assistant → Files to ignore); the file support is IDE-parsed, not a standard gitignore glob engine.

**gemini-aiexclude**
URL: https://cloud.google.com/gemini/docs/codeassist/create-aiexclude-file
Accessed: 2026-08-04
Quote: "Create a .aiexclude file to exclude source files from Gemini Code Assist. Use patterns similar to .gitignore"

**gemini-cli**
URL: https://aicodingtools.blog/en/gemini-cli/gemini-ignore
Accessed: 2026-08-04
Quote: "Gemini CLI respects .geminiignore for excluding files from context"

**sixarm-aiexclude**
URL: https://github.com/SixArm/aiexclude
Accessed: 2026-08-04
Quote: "A proposed open standard for AI code-assistant ignore files, using gitignore-compatible glob patterns"

**github-copilot-settings**
URL: https://docs.github.com/en/copilot/how-tos/configure-content-exclusion/exclude-content-from-copilot
Accessed: 2026-08-04
Quote: "GitHub Copilot does not support per-repository ignore files; configure exclusion via VS Code workspace settings or GitHub.com organization settings"

## SYNTHESIS

The ecosystem has converged on gitignore-compatible glob syntax across six+ independent tools, but has NOT converged on a single filename. Each vendor chose its own: `.aiderignore`, `.cursorignore`, `.aiignore` (JetBrains, partially), `.aiexclude` (Gemini), `.codeiumignore` (Codeium), `.geminiignore` (Gemini CLI). 

**Most complete documentation:** Aider's config reference is the most thorough, covering the pattern syntax fully.

**Gotcha—JetBrains:** Despite mentioning `.aiignore` in help docs, the primary mechanism is a UI toggle in project settings. File-based ignoring works but is not the canonical flow.

**Gotcha—GitHub Copilot:** No per-repo ignore file exists; exclusion is workspace-only and requires configuration outside the repo (in VS Code settings or GitHub.com org settings).

**Gotcha—Gemini:** Uses `.aiexclude` (not `.aiignore`), and the Gemini CLI (Antigravity) may use either `.geminiignore` or `.aiexclude` depending on version/context.

**Cross-tool strategy:** If you want one `.gitignore`-compatible file to work across multiple tools, `.aiexclude` (Gemini's choice) has the broadest reach, though not all tools support it. For maximum portability, maintain separate files or document the mutual ignoring strategy in CONTRIBUTING.
