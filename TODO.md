# UX Overhaul TODO

## Phase 1 - UX Foundation
- [ ] Add semantic dynamic color tokens in `AppTheme`.
- [ ] Replace hardcoded light/dark colors in Explore, Library, NovelDetail, Reader, Profile/Settings.
- [ ] Convert tap-only interactive surfaces to semantic `Button` where appropriate.
- [ ] Modernize obvious formatting and API usage (`String(format:)` hotspots in UI-facing text).
- [ ] Preserve existing behavior while normalizing visual hierarchy and accessibility labels.

## Phase 2 - Replace Key Placeholder UX
- [ ] Implement local Library search flow from header search action.
- [ ] Replace high-traffic placeholder alert actions with real navigation/usable UX.
- [ ] Disable no-backend actions with explicit unavailable messaging (instead of fake success).
- [ ] Keep add/remove Library interactions reversible and confirmed for destructive actions.

## Phase 3 - Targeted Refactor
- [ ] Extract maintainability subviews from oversized screen files without behavior changes.
- [ ] Keep architecture stable, only refactor where needed for UX velocity.

## Verification Gates
- [ ] Build succeeds on iPhone 17 Pro simulator.
- [ ] Unit tests pass for updated view model/store logic.
- [ ] UI tests pass for Explore -> Detail -> Reader -> Library core flow.
- [ ] Light/dark mode visual checks completed for key screens.
- [ ] Accessibility identifiers/labels verified for updated controls.
