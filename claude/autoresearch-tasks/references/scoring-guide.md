# Scoring Guide

## Dimension definitions

### Oracle strength (0-5)
- 0: No evaluator exists or can be conceived
- 1: Only manual human review can evaluate
- 2: Semi-automated checks exist (e.g., "it compiles")
- 3: Automated checks cover the happy path
- 4: Automated checks cover happy path + key error cases
- 5: Comprehensive automated evaluation with regression protection

### Oracle robustness (0-5)
- 0: Trivially gameable (e.g., "no errors in log" — just delete logging)
- 1: Easy to game with simple deletions
- 2: Requires some effort to game, but obvious shortcuts exist
- 3: Gaming requires non-trivial changes that would be visible in review
- 4: Gaming requires architectural changes that would be obviously wrong
- 5: Gaming is practically impossible without breaking the oracle itself

### Behavior preservation (0-5)
- 0: No protection against deletion-based shortcuts
- 1: Build must succeed (agent can delete features to fix build)
- 2: Tests must pass (agent can delete tests)
- 3: Test count must not decrease + surface manifest checked
- 4: Surface manifest locked + snapshot tests + API contract tests
- 5: Full behavioral specification with mutation testing or equivalent

### Scope tractability (0-5)
- 0: Entire system, no clear boundaries
- 1: Large subsystem with many external dependencies
- 2: Medium subsystem, some external deps manageable
- 3: Well-bounded subsystem, 1-2 external deps
- 4: Single component with clear interfaces
- 5: Pure function / isolated module with no external deps

### Expected autonomy duration (0-5)
- 0: Requires constant human input
- 1: Agent can work for minutes before needing help
- 2: Agent can work for 10-30 minutes autonomously
- 3: Agent can work for 1-2 hours autonomously
- 4: Agent can work for several hours autonomously
- 5: Agent can work for a full day+ autonomously

### Leverage created (0-5)
- 0: One-off task, no future benefit
- 1: Slight improvement to developer experience
- 2: Enables a few more automated checks
- 3: Unlocks a category of future autonomous tasks
- 4: Creates infrastructure for ongoing autonomous work
- 5: Transforms the repo from Tier 2/3 to Tier 1

## Composite scoring

Minimum thresholds (reject if below):
- Behavior preservation: >= 3
- Scope tractability: >= 3

Ranking formula (weighted):
```
composite = (oracle_strength * 0.20) +
            (oracle_robustness * 0.20) +
            (behavior_preservation * 0.25) +
            (scope_tractability * 0.15) +
            (autonomy_duration * 0.10) +
            (leverage_created * 0.10)
```

Behavior preservation gets the highest weight because it is the single most important property for safe autonomous work.
