# Plan: Design Paper Screens for Novel Detail + Audit Report

**Generated**: 2026-02-26
**Estimated Complexity**: Medium
**Primary Issue**: `ln-1c9`

## Overview
Create three Paper design deliverables grounded in the current SwiftUI implementation: two mobile Novel Detail states and one desktop Design Audit Report artboard. The plan prioritizes dark mode and accessibility gaps (contrast, readability, semantic labeling, and disabled-action clarity), while keeping outputs implementable against current architecture and UI tests.

## Prerequisites
- Access to Paper workspace/project for LoveNovel design files.
- Xcode workspace available for preview/runtime capture.
- iPhone 17 Pro simulator available for baseline screenshots.
- Existing source references:
  - `LoveNovel/Presentation/Features/NovelDetail/NovelDetailView.swift`
  - `LoveNovel/Theme/AppTheme.swift`
  - `LoveNovelUITests/NovelDetailNavigationUITests.swift`
- Apple documentation references reviewed for planning:
  - SwiftUI accessibility modifiers and labels
  - SwiftUI `colorScheme` / `colorSchemeContrast`
  - UIKit Dark Mode adaptive color guidance

## Scope Assumptions
- Mobile State A (recommended): loaded Novel Detail, Info tab, primary CTA visible.
- Mobile State B (recommended): loaded Novel Detail, Comments/Review context showing disabled backend actions with explanatory messaging.
- Desktop artboard: an audit/report board summarizing findings, severity, evidence, and recommendations.

## Dependency Graph

```text
T1 ──┐
     ├── T3 ──┬── T4 ──┐
T2 ──┘        │        ├── T6 ──┬── T7 ── T8 ── T9 ── T10
              └── T5 ──┘        │
                                 └───────────────┘
```

## Sprint 1: Baseline + Audit Inputs
**Goal**: Lock the baseline and constraints so downstream design work is accurate and implementable.
**Demo/Validation**:
- Baseline captures exist for light/dark contexts.
- Accessibility/dark-mode checklist is documented.
- Artboard specs for the three deliverables are explicit and approved for execution.

### T1: Capture Baseline UI Evidence
- **id**: `T1`
- **depends_on**: []
- **Location**: `LoveNovel/Presentation/Features/NovelDetail/NovelDetailView.swift`, `.artifacts/design/novel-detail-baseline/`
- **Description**: Capture current Novel Detail states (loading, loaded-info, loaded-comments/review) in light and dark mode from simulator/preview to anchor the redesign.
- **Complexity**: 3
- **Acceptance Criteria**:
  - Baseline imagery exists for both color schemes.
  - Captures include current disabled-action messaging and tab behavior.
- **Validation**:
  - Run preview/simulator captures and verify files under `.artifacts/design/novel-detail-baseline/`.
- **status**: Not Completed
- **log**:
- **files edited/created**:

### T2: Build Accessibility + Dark Mode Audit Checklist
- **id**: `T2`
- **depends_on**: []
- **Location**: `Docs/Design/novel-detail-accessibility-checklist.md` (new)
- **Description**: Create a checklist derived from current code and Apple guidance: contrast behavior, semantic colors, Dynamic Type resilience, VoiceOver labels, tappable target clarity, and disabled-state communication.
- **Complexity**: 4
- **Acceptance Criteria**:
  - Checklist includes measurable pass/fail criteria.
  - Checklist maps each criterion to observed UI zones.
- **Validation**:
  - Manual review confirms each criterion is testable and not vague.
- **status**: Not Completed
- **log**:
- **files edited/created**:

### T3: Define Paper Artboard Specifications
- **id**: `T3`
- **depends_on**: [`T1`, `T2`]
- **Location**: `Docs/Design/novel-detail-paper-spec.md` (new), Paper workspace
- **Description**: Lock exact content/layout requirements for Mobile State A, Mobile State B, and Desktop Audit Report board, including expected annotations and export naming.
- **Complexity**: 4
- **Acceptance Criteria**:
  - Spec defines required sections for each artboard.
  - Spec includes export names, dimensions, and annotation schema.
- **Validation**:
  - Checklist walkthrough confirms all issue requirements are covered.
- **status**: Not Completed
- **log**:
- **files edited/created**:

## Sprint 2: Mobile Novel Detail Artboards
**Goal**: Deliver two production-ready mobile artboards that reflect current behavior while improving dark mode/accessibility clarity.
**Demo/Validation**:
- Two mobile artboards exist in Paper and are exportable.
- Each artboard includes explicit accessibility and dark-mode notes.

### T4: Build Mobile State A Artboard
- **id**: `T4`
- **depends_on**: [`T3`]
- **Location**: Paper workspace (`Novel Detail / Mobile State A`), `.artifacts/design/paper-exports/`
- **Description**: Design loaded-info state with hero, tabs, primary CTA, and library interaction treatment aligned with current app hierarchy.
- **Complexity**: 5
- **Acceptance Criteria**:
  - Hero, tab strip, and bottom action region are represented.
  - Typography and spacing choices are documented in annotations.
- **Validation**:
  - Exported frame passes checklist items relevant to info state.
- **status**: Not Completed
- **log**:
- **files edited/created**:

### T5: Build Mobile State B Artboard
- **id**: `T5`
- **depends_on**: [`T3`]
- **Location**: Paper workspace (`Novel Detail / Mobile State B`), `.artifacts/design/paper-exports/`
- **Description**: Design loaded comments/review state emphasizing disabled backend actions and reason visibility while preserving interaction hierarchy.
- **Complexity**: 5
- **Acceptance Criteria**:
  - Disabled affordances are visually distinguishable in both light/dark contexts.
  - Explanatory reason text remains legible and discoverable.
- **Validation**:
  - Exported frame passes checklist items for disabled-action communication.
- **status**: Not Completed
- **log**:
- **files edited/created**:

### T6: Annotate Mobile Artboards for Accessibility + Dark Mode
- **id**: `T6`
- **depends_on**: [`T2`, `T4`, `T5`]
- **Location**: Paper workspace annotations, `Docs/Design/novel-detail-a11y-darkmode-notes.md` (new)
- **Description**: Add explicit annotations for contrast intent, semantic color usage, text scaling behavior, and accessibility identifier mapping for critical controls.
- **Complexity**: 4
- **Acceptance Criteria**:
  - Both mobile artboards include annotation callouts.
  - Annotation doc maps major controls to existing UI identifiers where applicable.
- **Validation**:
  - Cross-check against `NovelDetailNavigationUITests` identifiers and checklist.
- **status**: Not Completed
- **log**:
- **files edited/created**:

## Sprint 3: Desktop Audit Report + Handoff
**Goal**: Produce a desktop report artboard and ship a complete handoff package with verification and implementation traceability.
**Demo/Validation**:
- Desktop audit report artboard complete and linked to evidence.
- Risks and recommended implementation sequence are explicit.
- Handoff package is complete and actionable.

### T7: Create Desktop Design Audit Report Artboard
- **id**: `T7`
- **depends_on**: [`T3`, `T6`]
- **Location**: Paper workspace (`Novel Detail / Desktop Audit Report`), `.artifacts/design/paper-exports/`
- **Description**: Build a desktop board that summarizes findings, severity, evidence screenshots, and design recommendations prioritized by impact/effort.
- **Complexity**: 6
- **Acceptance Criteria**:
  - Includes issue matrix (ID, severity, area, recommendation).
  - Includes before/after or baseline/proposed references.
- **Validation**:
  - Audit board traceably links each recommendation to checklist criteria.
- **status**: Not Completed
- **log**:
- **files edited/created**:

### T8: Implementation Feasibility Trace
- **id**: `T8`
- **depends_on**: [`T6`, `T7`]
- **Location**: `Docs/Design/novel-detail-implementation-trace.md` (new)
- **Description**: Map each recommendation to concrete code zones and likely change size (small/medium/large), focusing on low-risk first-pass candidates.
- **Complexity**: 5
- **Acceptance Criteria**:
  - Every recommendation has file-level traceability.
  - Sequence proposed respects architecture boundaries.
- **Validation**:
  - Manual trace review against `NovelDetailView.swift`, `AppTheme.swift`, and relevant tests.
- **status**: Not Completed
- **log**:
- **files edited/created**:

### T9: Verification Pass (Design + Runtime)
- **id**: `T9`
- **depends_on**: [`T8`]
- **Location**: `.artifacts/design/verification/`, Xcode build/test outputs
- **Description**: Validate design assumptions against current app behavior via targeted runtime checks and evidence capture.
- **Complexity**: 4
- **Acceptance Criteria**:
  - Project builds cleanly.
  - Targeted Novel Detail UI tests pass.
  - Verification screenshots align with audit evidence references.
- **Validation**:
  - `mcp__xcode__BuildProject`
  - `mcp__xcode__RunSomeTests` for `NovelDetailNavigationUITests`
  - Preview/simulator screenshots captured.
- **status**: Not Completed
- **log**:
- **files edited/created**:

### T10: Delivery + Tracker Closure Notes
- **id**: `T10`
- **depends_on**: [`T9`]
- **Location**: `Docs/Design/novel-detail-delivery-summary.md` (new), `br close ln-1c9 --reason ...`
- **Description**: Package final links/exports/checklists, summarize decisions and tradeoffs, and prepare closure evidence for tracker update.
- **Complexity**: 3
- **Acceptance Criteria**:
  - Delivery summary includes links to 3 artboards and verification evidence.
  - Closure reason includes what changed and how it was validated.
- **Validation**:
  - Delivery checklist complete and reviewable in one place.
- **status**: Not Completed
- **log**:
- **files edited/created**:

## Parallel Execution Groups

| Wave | Tasks | Can Start When |
|------|-------|----------------|
| 1 | `T1`, `T2` | Immediately |
| 2 | `T3` | `T1` + `T2` complete |
| 3 | `T4`, `T5` | `T3` complete |
| 4 | `T6` | `T2` + `T4` + `T5` complete |
| 5 | `T7` | `T3` + `T6` complete |
| 6 | `T8` | `T6` + `T7` complete |
| 7 | `T9` | `T8` complete |
| 8 | `T10` | `T9` complete |

## Testing Strategy
- Design validation:
  - Checklist-based review against dark-mode/accessibility criteria.
  - Baseline vs proposed side-by-side comparisons.
- Runtime validation:
  - Build app to ensure referenced behavior is current.
  - Run targeted Novel Detail UI tests to confirm interaction assumptions.
- Traceability validation:
  - Every audit recommendation links to a code location and a visual evidence item.

## Potential Risks & Gotchas
- Ambiguous interpretation of the two required mobile states.
  - Mitigation: lock state definitions in `T3` before artboard production.
- Designs that look good but are costly or risky to implement.
  - Mitigation: enforce `T8` feasibility mapping prior to sign-off.
- Dark-mode fixes relying on static colors that regress contrast.
  - Mitigation: require semantic/adaptive color strategy callouts in `T6`.
- Accessibility annotations not aligned with actual identifiers.
  - Mitigation: cross-check with `NovelDetailNavigationUITests` and view identifiers.

## Rollback Plan
- If proposed designs fail feasibility review, revert to baseline-aligned variants and keep audit report recommendations separated as future work.
- If verification reveals behavior drift, pause delivery and refresh baseline captures before final handoff.
- Keep exported versions immutable with timestamped filenames to recover prior approved states quickly.
