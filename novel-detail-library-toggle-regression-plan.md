# Plan: Novel Detail Library Toggle UX + Regression Coverage

**Generated**: 2026-02-28
**Estimated Complexity**: Low
**Primary Issue**: `ln-1k2`

## Overview
Ship the smallest high-confidence slice already in progress: finalize the library toggle feedback in Novel Detail, add one UI regression test for add/remove confirmation flow, and verify with targeted build/tests.

Assumption: focus only on `NovelDetail` add/remove interactions and avoid broader UX refactors in this pass.

## Prerequisites
- Xcode workspace available.
- iPhone 17 Pro simulator available.
- Existing files:
  - `LoveNovel/Presentation/Features/NovelDetail/NovelDetailView.swift`
  - `LoveNovelUITests/NovelDetailNavigationUITests.swift`

## Dependency Graph

```text
T1 ──┬── T2 ──┬── T4 ──┬── T5 ── T6
     │        └── T3 ──┘
     └────────────────────────────┘
```

## Sprint 1: Finalize UX Slice
**Goal**: Make the current local `NovelDetail` interaction update production-safe and testable.
**Demo/Validation**:
- Add/remove library interaction remains functional.
- Visual feedback does not regress readability or interaction clarity.

### T1: Confirm Scope + Acceptance
- **id**: `T1`
- **depends_on**: []
- **Location**: `TODO.md`, `LoveNovel/Presentation/Features/NovelDetail/NovelDetailView.swift`
- **Description**: Lock the boundary of this slice (no broad redesign, no unrelated refactor) and confirm target behavior: tap add -> state flips to in-library, tap again -> confirmation appears, confirm remove -> state flips back.
- **Acceptance Criteria**:
  - Scope excludes unrelated screens/components.
  - Expected interaction flow is explicitly documented in task log/PR notes.
- **Validation**:
  - Manual checklist review before coding.
- **status**: Completed
- **log**: Scoped execution to NovelDetail add/remove flow only and parked broader UX backlog work.
- **files edited/created**: `novel-detail-library-toggle-regression-plan.md`

### T2: Harden Library Toggle Feedback Behavior
- **id**: `T2`
- **depends_on**: [`T1`]
- **Location**: `LoveNovel/Presentation/Features/NovelDetail/NovelDetailView.swift`
- **Description**: Finalize pulse-ring/symbol feedback implementation with safe defaults (consistent visibility, no broken animation state).
- **Acceptance Criteria**:
  - Toggle interaction remains responsive for both add and remove paths.
  - Visual feedback works in both icon contexts used in Novel Detail.
  - No behavior regression for disabled toggle state.
- **Validation**:
  - Local run + manual interaction check in simulator.
- **status**: Completed
- **log**: Updated toggle icon ring to accept context-specific ring color and added stable confirmation dialog button identifiers.
- **files edited/created**: `LoveNovel/Presentation/Features/NovelDetail/NovelDetailView.swift`

### T3: Add Accessibility-Safe Animation Guard
- **id**: `T3`
- **depends_on**: [`T1`]
- **Location**: `LoveNovel/Presentation/Features/NovelDetail/NovelDetailView.swift`
- **Description**: Make animation behavior safe for accessibility preferences (reduce-motion aware fallback behavior).
- **Acceptance Criteria**:
  - Toggle still updates state when motion is reduced.
  - No reliance on animation for conveying state change.
- **Validation**:
  - Manual verification with reduced motion preference.
- **status**: Completed
- **log**: Added `accessibilityReduceMotion` guard in animation path so state changes remain functional without motion effects.
- **files edited/created**: `LoveNovel/Presentation/Features/NovelDetail/NovelDetailView.swift`

## Sprint 2: Regression Coverage + Verification
**Goal**: Add durable regression protection and confirm compile/test health.
**Demo/Validation**:
- UI test covers add/remove confirmation interaction.
- Build + targeted UI tests pass.

### T4: Add Novel Detail Add/Remove Regression Test
- **id**: `T4`
- **depends_on**: [`T2`, `T3`]
- **Location**: `LoveNovelUITests/NovelDetailNavigationUITests.swift`
- **Description**: Add one focused UI test that exercises add-to-library, remove confirmation dialog visibility, confirm remove, and expected state/interaction continuity.
- **Acceptance Criteria**:
  - Test fails on broken add/remove flow and passes on valid flow.
  - Test is deterministic with existing launch configuration.
- **Validation**:
  - Run targeted UI test suite that includes the new case.
- **status**: Completed
- **log**: Added `testLibraryToggleAddRemoveFlowShowsConfirmationAndRemovesOnConfirm`; normalized initial state and used `firstMatch` to avoid duplicate-query tap failures.
- **files edited/created**: `LoveNovelUITests/NovelDetailNavigationUITests.swift`

### T5: Build + Targeted Test Verification
- **id**: `T5`
- **depends_on**: [`T4`]
- **Location**: Xcode MCP build/test outputs
- **Description**: Validate final change set through project build, targeted Novel Detail UI tests, and issue navigator check.
- **Acceptance Criteria**:
  - Project builds successfully.
  - `NovelDetailNavigationUITests` targeted run passes.
  - No new Xcode navigator errors tied to touched files.
- **Validation**:
  - `mcp__xcode__BuildProject`
  - `mcp__xcode__RunSomeTests` (`LoveNovelUITests/NovelDetailNavigationUITests`)
  - `mcp__xcode__XcodeListNavigatorIssues`
- **status**: Completed
- **log**: Build passed; targeted UI tests passed for no-backend action state and add/remove regression flow; Issue Navigator reports zero errors.
- **files edited/created**: Xcode MCP outputs only

### T6: Delivery + Tracker Closure
- **id**: `T6`
- **depends_on**: [`T5`]
- **Location**: `br` tracker + git history
- **Description**: Close `ln-1k2` with evidence, including what changed and how it was verified.
- **Acceptance Criteria**:
  - `br close ln-1k2` includes concrete verification evidence.
  - Working tree is understandable (intentional remaining changes only).
- **Validation**:
  - `br close ln-1k2 --reason "..."`
  - `br ready --json --limit 10` shows next actionable queue.
- **status**: Completed
- **log**: Closed `ln-1k2` with implementation + MCP verification evidence; confirmed tracker queue is empty (`br ready` -> `[]`).
- **files edited/created**: `.beads/issues.jsonl`

## Testing Strategy
- Add one focused UI regression test for add/remove confirmation flow.
- Run targeted UI test suite for Novel Detail navigation/interaction.
- Run project build on iPhone 17 Pro simulator.
- Check Xcode Issue Navigator for introduced regressions.

## Potential Risks & Gotchas
- Existing unrelated local changes may contaminate this slice.
  - Mitigation: stage only touched files for this task.
- UI test flakiness due to loading timing.
  - Mitigation: reuse existing helper waits and deterministic launch data.
- Animation-only feedback can reduce accessibility clarity.
  - Mitigation: preserve clear icon/state switch independent of animation.

## Rollback Plan
- Revert `NovelDetailView` changes if interaction stability regresses.
- Keep regression test if it still captures valid behavior; otherwise adjust to pre-change baseline.
- Re-run targeted UI tests before reattempting.
