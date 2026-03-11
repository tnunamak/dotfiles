Review the current branch diff against the base branch (usually `main`) and remove AI-generated slop, including:
- Extra comments a human wouldn't add or that are inconsistent with the rest of the file.
- Extra defensive checks or try/catch blocks that are abnormal for this area of the codebase, especially when callers already validate inputs.
- Casts to `any` (or similar escape hatches) added just to get around type issues.
- Any style, naming, or structure that doesn't match the surrounding code.

Keep changes minimal and focused on cleanup only; don't add features or refactors. When done, summarize what changed in 1-3 sentences.
