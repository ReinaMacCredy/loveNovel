# LoveNovel Knowledge Base

iOS novel-reader app. SwiftUI, Swift 6, XcodeGen. No external dependencies.

## Structure

```
LoveNovel/
  LoveNovelApp.swift          # @main entry, launches RootTabView
  App/RootTabView.swift        # TabView (Library | Explore | Profile), default: Explore
  Features/
    Explore/                   # Feed-driven book discovery, navigates to NovelDetail
      ExploreView.swift        # NavigationStack + ScrollView. Tapping book cover pushes NovelDetailView.
      ExploreViewModel.swift   # Phase state machine: idle -> loading -> loaded | failed
      Components/              # BookCoverStrip, FeaturedBookCard, SectionHeader
    NovelDetail/               # Book detail with tabbed content (Info/Review/Comments/Content)
      NovelDetailView.swift    # 864 lines. Hero + tab strip + phase content + bottom action bar.
                               #   Contains 4 private types: ReaderDestination, HeroCoverCard,
                               #   AuthorRelatedBookCard, UploaderRelatedBookCard.
      NovelDetailViewModel.swift  # Phase state machine + Tab/CommentSort/ChapterOrder enums.
                               #   Manages detail loading, chapter display, comment sorting.
    Reader/                    # Chapter reader with theming and control panel
      ReaderView.swift         # 605 lines. Themed reading surface + bottom panel (info/settings)
                               #   + tutorial overlay. Theme-aware colors computed in view.
      ReaderViewModel.swift    # PanelTab, ReadingMode, ReaderThemeStyle (8 themes). Chapter
                               #   navigation via slider/buttons. Font and size selection.
    Library/                   # Empty-state placeholder (History/Bookmark segments, no data yet)
    Profile/                   # Menu list -> Settings navigation
      SettingsView.swift       # Simple settings list (Languages, Dark mode rows). 74 lines.
  Data/
    CatalogProviding.swift     # Protocol (Sendable). fetchHomeFeed() async throws -> HomeFeed
    CatalogRepository.swift    # Actor. Loads/caches mock_catalog.json. CatalogSource enum for DI.
    BookDetailProviding.swift  # Protocol (Sendable). fetchDetail(for:) async throws -> BookDetail
    BookDetailRepository.swift # Actor. Loads/caches mock_book_details.json. BookDetailSource enum
                               #   for DI. Fallback detail for unknown books. BundleToken pattern.
  Models/
    Book.swift                 # Codable + Identifiable + Sendable + Equatable. Fields: id, title,
                               #   author, summary, rating, accentHex
    HomeFeed.swift             # Codable + Sendable + Equatable. Sections: latest, featured (single),
                               #   recommended, moreLikeThis
    BookDetail.swift           # BookDetail (chapterCount, genres, tags, reviews, comments, related
                               #   books). Also: RelatedBook, BookPublicationStatus, BookChapter,
                               #   BookReview, BookComment - all Codable + Sendable + Equatable.
  Theme/AppTheme.swift         # Design tokens: Colors (static), Layout (static). Color(hex:) extension.
  Resources/                   # mock_catalog.json, mock_book_details.json
project.yml                    # XcodeGen spec. iOS 26.0 target. Source of truth for .xcodeproj
LoveNovelTests/                # Unit: CatalogRepository, BookDetailRepository, ExploreViewModel,
                               #   NovelDetailViewModel, ReaderViewModel
LoveNovelUITests/              # UI: TabNavigation, NovelDetailNavigation (Explore->Detail->Reader)
```

## Where to Look

| Task | Location | Notes |
|------|----------|-------|
| Add new feature tab | `App/RootTabView.swift` | Add to `AppTab` enum + new tab case in TabView |
| Add new Explore section | `ExploreView.loadedContent()` | Follow pattern: `SectionHeader` + `BookCoverStrip` |
| New reusable component | `Features/Explore/Components/` | Only Explore has shared components currently |
| New domain model | `Models/` | Must be `Codable + Sendable + Equatable` |
| Add data source | `Data/` | Create protocol (Sendable) + actor repository. See `BookDetailProviding`/`BookDetailRepository` |
| Change colors/spacing | `Theme/AppTheme.swift` | All tokens centralized here. Reader themes in `ReaderView` |
| Add new screen to Profile | `Features/Profile/` | Push via `NavigationLink` inside `ProfileView` |
| Add NovelDetail tab | `NovelDetailView.loadedContent()` | Switch on `viewModel.selectedTab`, add case to `Tab` enum |
| Add reader setting | `ReaderView.panelSettingsContent` | Add control in settings panel, state in `ReaderViewModel` |
| Navigate to reader | `NovelDetailView.openReader()` | Sets `readerDestination`, triggers `navigationDestination` |

## Code Map

| Symbol | Type | Location | Role |
|--------|------|----------|------|
| `CatalogProviding` | protocol | Data/ | Home feed data boundary. |
| `CatalogRepository` | actor | Data/ | Loads/caches mock_catalog.json. |
| `BookDetailProviding` | protocol | Data/ | Book detail data boundary. |
| `BookDetailRepository` | actor | Data/ | Loads/caches mock_book_details.json. Fallback for unknown books. |
| `ExploreViewModel` | @MainActor class | Features/Explore/ | Feed loading + placeholder alerts. Phase-driven UI. |
| `NovelDetailViewModel` | @MainActor class | Features/NovelDetail/ | Detail loading + tab/sort/chapter state. Phase-driven UI. |
| `ReaderViewModel` | @MainActor class | Features/Reader/ | Reading state: theme, font, chapter nav, control panel, tutorial. |
| `LibraryViewModel` | @MainActor class | Features/Library/ | Segment selection only. No data loading. |
| `AppTab` | enum | App/ | Tab definition. Used in RootTabView selection binding. |
| `BookCoverSize` | enum | Features/Explore/Components/ | .compact and .regular cover sizes. |
| `AppTheme` | enum | Theme/ | Namespace for `Colors` and `Layout` static tokens. |
| `ReaderDestination` | private struct | Features/NovelDetail/ | Identifiable + Hashable. Drives navigation from detail to reader. |

## Navigation Flow

```
RootTabView (TabView)
  +-- LibraryView (empty state)
  +-- ExploreView (NavigationStack)
  |     +--[tap book cover]--> NovelDetailView (navigationDestination)
  |                              +--[tap chapter / "Read Now"]--> ReaderView (navigationDestination)
  +-- ProfileView (NavigationStack)
        +--[tap Settings]--> SettingsView (NavigationLink)
```

## Conventions

- **Swift 6 strict concurrency**: `SWIFT_STRICT_CONCURRENCY=complete`. All models `Sendable`. Data layer uses `actor`. View models use `@MainActor`.
- **XcodeGen**: `project.yml` is the source of truth. Run `xcodegen generate` after any change. Never hand-edit `.xcodeproj`.
- **View model injection**: `ExploreView` takes view model via `@autoclosure` init. `NovelDetailView` takes `Book` directly (creates VM internally) or VM via `@autoclosure`. `ReaderView` takes explicit params.
- **State machine pattern**: All data-loading view models use `Phase` enum (idle/loading/loaded/failed). Guard `.loading` and early-return `.loaded` in `load()`.
- **Cancellation handling**: Repositories and view models check `Task.isCancelled` explicitly. Catch `CancellationError` separately from generic errors.
- **Repository pattern**: Protocol (Sendable) defines boundary. Actor implements with caching. `Source` enum for DI (`.bundled` vs `.rawData`). `BundleToken` fallback for test bundles.
- **Test data**: Tests use inline `static let` sample data, not shared fixtures. Repository tests use `.rawData()` source. VM tests use private stub structs implementing the protocol with closure injection.
- **Accessibility IDs**: Screens: `screen.{name}`. Detail tabs: `novel_detail.tab.{name}`. Reader: `reader.{element}`. Book covers: `book.cover.{id}`.
- **Previews**: `#Preview` macro at bottom of every view file.
- **Vietnamese UI**: Reader panel labels and NovelDetail genre/tag headers use Vietnamese strings.

## Anti-Patterns

- Do NOT add external dependencies (no SPM/CocoaPods/Carthage configured).
- Do NOT hand-edit `LoveNovel.xcodeproj` - use `project.yml` + `xcodegen generate`.
- Do NOT suppress concurrency warnings - fix them properly (actors, @MainActor, Sendable).
- Do NOT create shared test fixtures - each test class owns its sample data inline.
- Do NOT add default exports or barrel files - Swift does not use this pattern.
- Do NOT put reusable types inside view files - `NovelDetailView.swift` already has 4 private types; extract to separate files if adding more.

## Gotchas

- `NovelDetailView.swift` (864 lines) is the largest file. Contains 4 private types (ReaderDestination, HeroCoverCard, AuthorRelatedBookCard, UploaderRelatedBookCard). Extract to separate files if adding complexity.
- `ReaderView.swift` (605 lines) computes theme-aware colors inline (readerBackgroundColor, readerPrimaryTextColor). These are not in AppTheme - they live in the view.
- `ReaderViewModel` uses Vietnamese strings for UI labels (e.g., PanelTab raw values: "Thong tin", "Cai dat"; ReadingMode: "Lat trang", "Cuon doc"). Keep consistent when adding labels.
- Many features are v2 stubs showing "Coming Soon" alerts (`alertMessage`, `showPlaceholder`). Do not mistake these for real implementations.
- `Color(hex:)` extension handles 3, 6, and 8 character hex strings. Falls back to `.gray` on parse failure.
- `BookDetailRepository.fallbackDetail` returns synthetic data for books not in JSON. Tests assert against this fallback.
- `ReaderView` uses `@AppStorage("reader.didShowTutorial")` to persist tutorial state across launches.
- `ExploreView` navigates to `NovelDetailView` via `navigationDestination(item: $selectedBook)`. `NovelDetailView` navigates to `ReaderView` via `navigationDestination(item: $readerDestination)`.
- Library placeholder buttons (search, gear) have empty closures - v1 stubs.

## Commands

```bash
# Build
xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Test (unit + UI)
xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Regenerate xcodeproj after project.yml changes
xcodegen generate

# Open in Xcode
open LoveNovel.xcodeproj
```

## MCP Tool Playbook

Use the `mcp__xcode__*` toolset as the preferred path for Xcode-aware build/test/diagnostics workflows. Direct shell/file read-write-edit is still allowed when faster and sufficient.

1. **Project and context bootstrap**:
   - `mcp__xcode__XcodeListWindows` to discover the active workspace window and `tabIdentifier`
   - `mcp__xcode__XcodeLS`, `mcp__xcode__XcodeGlob`, `mcp__xcode__XcodeGrep` to inspect the project quickly from Xcode context
2. **Build and test loop**:
   - `mcp__xcode__BuildProject` for compile checks
   - `mcp__xcode__GetBuildLog` to inspect compiler/build failures
   - `mcp__xcode__GetTestList` to discover test identifiers
   - `mcp__xcode__RunSomeTests` for targeted regression checks
   - `mcp__xcode__RunAllTests` for full suite runs
3. **Diagnostics and validation**:
   - `mcp__xcode__XcodeListNavigatorIssues` for current Issue Navigator visibility
   - `mcp__xcode__XcodeRefreshCodeIssuesInFile` for file-scoped diagnostics
   - `mcp__xcode__RenderPreview` for SwiftUI preview verification
   - `mcp__xcode__ExecuteSnippet` for quick runtime checks in source context
4. **Project-aware editing (optional path)**:
   - `mcp__xcode__XcodeRead`, `mcp__xcode__XcodeUpdate`, `mcp__xcode__XcodeWrite` for file edits through Xcode project structure
   - `mcp__xcode__XcodeMakeDir`, `mcp__xcode__XcodeMV`, `mcp__xcode__XcodeRM` for project navigator structure updates
5. **Shell editing path (default for speed)**:
   - Use `rg`, `sed`, `cat`, and `apply_patch` for local workspace edits
   - Prefer shell editing unless Xcode runtime/build context is required

### Screenshot + Debug Quick Reference

- `mcp__xcode__RenderPreview` is the primary tool for auto-capturing SwiftUI preview snapshots.
- Use `mcp__xcode__DocumentationSearch` to query official Apple Developer docs before/while implementing new APIs.
- Use `mcp__xcode__BuildProject` + `mcp__xcode__GetBuildLog` for compile/debug loops.
- Use `mcp__xcode__XcodeListNavigatorIssues` and `mcp__xcode__XcodeRefreshCodeIssuesInFile` for diagnostics.
- Use `mcp__xcode__RunSomeTests` / `mcp__xcode__RunAllTests` and `mcp__xcode__ExecuteSnippet` for runtime debugging.
- There is no direct Xcode MCP tool for live simulator screen capture; use shell fallback: `xcrun simctl io booted screenshot <output-path>`.

### Always-Use Rules

- **Always use the iPhone 17 Pro simulator** for build, test, and run workflows. Do not use any other simulator device unless explicitly requested.
- Direct read/write/edit without MCP is allowed.
- Use `mcp__xcode__*` tools when build/test/diagnostic context is needed.
- Call `mcp__xcode__XcodeListWindows` first when a `tabIdentifier` is required.
- Always read/search before editing (via Xcode tools or shell tools).
- Always build after modifications; do not leave the project in a broken build state.
- Always run tests for changed behavior (targeted minimum, full suite for broad refactors).
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
