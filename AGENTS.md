# LoveNovel Knowledge Base

iOS novel-reader app. SwiftUI, Swift 6, XcodeGen. No external dependencies.

## Structure

```
LoveNovel/
  LoveNovelApp.swift          # @main entry, launches RootTabView
  App/RootTabView.swift        # Tab navigation (Library | Explore | Profile), default: Explore
  Features/
    Explore/                   # Feed-driven book discovery (only feature with real data flow)
      ExploreView.swift        # ScrollView with scroll-direction tracking for tab bar auto-hide
      ExploreViewModel.swift   # Phase state machine: idle -> loading -> loaded | failed
      Components/              # BookCoverStrip, FeaturedBookCard, SectionHeader
    Library/                   # Empty-state placeholder (History/Bookmark segments, no data yet)
    Profile/                   # Menu list -> Settings navigation
      SettingsView.swift       # 297 lines - contains DarkModeSettingsView, ThemePaletteRow,
                               #   BorderedSegmentedControl, LanguageOption, DarkModeOption (all private)
  Data/
    CatalogProviding.swift     # Protocol (Sendable). Single method: fetchHomeFeed() async throws -> HomeFeed
    CatalogRepository.swift    # Actor. Loads/caches mock_catalog.json from bundle. CatalogSource enum
                               #   for DI (.bundled vs .rawData). BundleToken fallback for test bundles.
  Models/
    Book.swift                 # Codable + Identifiable + Sendable + Equatable. Fields: id, title, author,
                               #   summary, rating, accentHex
    HomeFeed.swift             # Codable + Sendable + Equatable. Sections: latest, featured (single), 
                               #   recommended, moreLikeThis
  Theme/AppTheme.swift         # Design tokens: Colors (static), Layout (static). Color(hex:) extension.
  Resources/mock_catalog.json  # Bundled sample data
project.yml                    # XcodeGen spec. Source of truth for LoveNovel.xcodeproj
LoveNovelTests/                # Unit: CatalogRepositoryTests, ExploreViewModelTests, ExploreViewScrollTests
LoveNovelUITests/              # UI: TabNavigationUITests (launch + tab switching)
```

## Where to Look

| Task | Location | Notes |
|------|----------|-------|
| Add new feature tab | `App/RootTabView.swift` | Add to `AppTab` enum + both `modernTabView` (iOS 18+) and `legacyTabView` |
| Add new Explore section | `ExploreView.loadedContent()` | Follow pattern: `SectionHeader` + `BookCoverStrip` |
| New reusable component | `Features/Explore/Components/` | Only Explore has shared components currently |
| New domain model | `Models/` | Must be `Codable + Sendable + Equatable` |
| Add data source | `Data/` | Implement `CatalogProviding`, inject via view model init |
| Change colors/spacing | `Theme/AppTheme.swift` | All tokens centralized here |
| Add new screen to Profile | `Features/Profile/` | Push via `NavigationLink` inside `ProfileView` |

## Code Map

| Symbol | Type | Location | Role |
|--------|------|----------|------|
| `CatalogProviding` | protocol | Data/ | Data abstraction boundary. All data access goes through this. |
| `CatalogRepository` | actor | Data/ | Concrete data provider. Caches after first load. |
| `ExploreViewModel` | class (@MainActor) | Features/Explore/ | Only view model with real data flow. Phase enum drives UI state. |
| `LibraryViewModel` | class (@MainActor) | Features/Library/ | Segment selection only. No data loading. |
| `AppTab` | enum | App/ | Tab definition. Used in RootTabView selection binding. |
| `ExploreScrollDirection` | enum | Features/Explore/ | Drives tab bar visibility. Referenced by RootTabView. |
| `BookCoverSize` | enum | Features/Explore/Components/ | .compact (56x56) and .regular (118x168) cover sizes. |
| `AppTheme` | enum | Theme/ | Namespace for `Colors` and `Layout` static tokens. |

## Conventions

- **Swift 6 strict concurrency**: `SWIFT_STRICT_CONCURRENCY=complete`. All models are `Sendable`. Data layer uses `actor`. View models use `@MainActor`.
- **XcodeGen**: `project.yml` is the source of truth. Run `xcodegen generate` after any change. Never hand-edit `.xcodeproj`.
- **iOS version branching**: `RootTabView` has `@available(iOS 18.0, *)` for new `Tab` API with `legacyTabView` fallback for iOS 17.
- **View model injection**: Views take view model via `@autoclosure` init parameter (see `ExploreView`). Repositories injected via protocol (`any CatalogProviding`).
- **State machine pattern**: `ExploreViewModel.Phase` enum (idle/loading/loaded/failed). Check `.loading` guard and `.loaded` early return in `load()`.
- **Cancellation handling**: Both `CatalogRepository` and `ExploreViewModel` check `Task.isCancelled` explicitly.
- **Test data**: Tests use inline `static let` sample data, not shared fixtures. `CatalogRepository` tests use `.rawData()` source for DI.
- **Accessibility IDs**: Screens use `screen.{name}` pattern (e.g., `screen.explore`, `screen.library`, `screen.profile`, `screen.settings`).
- **Previews**: `#Preview` macro at bottom of every view file.
- **MARK comments**: Used for section organization in views (e.g., `// MARK: - Tab Container`).

## Anti-Patterns

- Do NOT add external dependencies (no SPM/CocoaPods/Carthage configured).
- Do NOT hand-edit `LoveNovel.xcodeproj` - use `project.yml` + `xcodegen generate`.
- Do NOT suppress concurrency warnings - fix them properly (actors, @MainActor, Sendable).
- Do NOT create shared test fixtures - each test class owns its sample data inline.
- Do NOT add default exports or barrel files - Swift does not use this pattern.

## Gotchas

- `SettingsView.swift` (297 lines) contains 5 types (3 private views + 2 private enums). If adding more settings, consider extracting to separate files.
- `LibraryView.swift` line 42 has a stale `#imageLiteral` reference that may cause build issues.
- Many features are v2 stubs showing "Coming Soon" alerts (`showPlaceholder`). Do not mistake these for real implementations.
- `RootTabView` has dual tab implementations (iOS 17 legacy + iOS 18 modern). Both must be updated when adding/modifying tabs.
- `Color(hex:)` extension handles 3, 6, and 8 character hex strings. Falls back to `.gray` on parse failure.
- `CatalogRepository.resolveSource` has a `BundleToken` fallback to find resources in the correct bundle during testing.

## Commands

```bash
# Build
xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel -destination 'platform=iOS Simulator,name=iPhone 16' build

# Test (unit + UI)
xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel -destination 'platform=iOS Simulator,name=iPhone 16' test

# Regenerate xcodeproj after project.yml changes
xcodegen generate

# Open in Xcode
open LoveNovel.xcodeproj
```

## MCP Tool Playbook

Use `XcodeBuildMCP` as the preferred path for build/test/simulator workflows. Direct shell/file read-write-edit is allowed when faster and sufficient.

1. **Project and session bootstrap**:
   - `discover_projs` to find `.xcodeproj` / `.xcworkspace`
   - `list_schemes` and `list_sims` to pick scheme/simulator
   - `session_set_defaults` to set `projectPath/workspacePath`, `scheme`, simulator, and build config
   - `session_show_defaults` to verify active defaults
2. **Build and test loop**:
   - `build_sim` for compile checks
   - `test_sim` for unit/UI tests
   - `clean` when DerivedData/build artifacts cause issues
   - `show_build_settings` for build setting diagnosis
3. **Run on simulator**:
   - `boot_sim` / `open_sim` as needed
   - `build_run_sim` for fast build+launch cycle
   - `get_sim_app_path` + `install_app_sim` + `launch_app_sim` (or `launch_app_logs_sim`) for explicit install/launch flow
   - `stop_app_sim` to terminate app quickly
4. **Logs and UI validation**:
   - `start_sim_log_cap` and `stop_sim_log_cap` for targeted runtime logs
   - `snapshot_ui` for view hierarchy and frames
   - `screenshot` and `record_sim_video` for visual evidence
   - `get_app_bundle_id` when bundle-specific operations are needed
5. **Code navigation/editing**:
   - Direct path: `rg`, `sed`, `cat`, apply patches, and direct file edits in the workspace
   - Use shell editing by default unless Xcode runtime/build context is required

### Always-Use Rules

- Direct read/write/edit without MCP is allowed.
- Use `XcodeBuildMCP` tools when build/test/simulator context is needed.
- Always read/search before editing (via Xcode tools or shell tools).
- Always build after modifications; do not leave the project in a broken build state.
- Always run tests for changed behavior (targeted minimum, full suite for broad refactors).
- Always update both iOS 17 and iOS 18 paths when touching tab/navigation logic.
- Always use `xcodegen generate` after `project.yml` changes; never hand-edit `.xcodeproj`.

## Skill Auto-Load Policy

Load `swift-concurrency` at the start of every new chat in this repo.

- Skill path: `.agents/skills/swift-concurrency/SKILL.md`
- Default behavior:
  - Read and apply its guidance before making Swift code changes.
  - Keep Swift 6 strict concurrency compliance (`Sendable`, actor isolation, `@MainActor`, cancellation handling).
  - Treat concurrency safety as a non-optional quality gate.
- Trigger expansion: If a task mentions `async/await`, actors, data races, `Sendable`, `@MainActor`, or Swift 6 migration, apply the skill rules strictly and explicitly in implementation.

## Commits

Imperative, scoped: `feat:`, `fix:`, `test:`, `refactor:`. One logical change per commit.
PRs: summary + test evidence + screenshots for UI changes. Flag `project.yml` changes.
