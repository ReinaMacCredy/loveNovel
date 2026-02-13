# LoveNovel Knowledge Base

iOS novel-reader app. SwiftUI, Swift 6, XcodeGen. No external dependencies.

## Build, Test, and Lint Commands

```bash
# Build project
xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run all tests (unit + UI)
xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Run a single test class
xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:LoveNovelTests/ExploreViewModelTests

# Run a single test method
xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:LoveNovelTests/ExploreViewModelTests/testLoadSuccess

# Run a specific UI test
xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:LoveNovelUITests/TabNavigationTests

# Regenerate xcodeproj after project.yml changes
xcodegen generate

# Open in Xcode
open LoveNovel.xcodeproj
```

Note: There is no SwiftLint configured. The project relies on Swift compiler warnings and Xcode's static analysis.

## Code Style Guidelines

### Imports

```swift
import SwiftUI      // Framework imports first
import Foundation   // Standard library second
// Third-party imports (none in this project)
// Internal imports last, grouped by module
```

- One import per line. No grouping with parentheses.
- Sort alphabetically within each group.

### Types and Protocols

All models must conform to:

```swift
struct Book: Codable, Identifiable, Sendable, Equatable, Hashable {
    let id: String
    let title: String
}
```

- Use `struct` for data models.
- Always include `Sendable` for Swift 6 concurrency safety.
- Always include `Codable` for JSON serialization.
- Include `Equatable` and `Hashable` where useful for UI state.

### Enums

```swift
enum Phase: Equatable {
    case idle
    case loading
    case loaded
    case failed
}
```

- Use raw values for enums that map to strings (e.g., localization keys).
- Include `Equatable` for state machine enums used in UI.

### Error Handling

Custom errors use `LocalizedError`:

```swift
enum CatalogRepositoryError: LocalizedError {
    case missingResource(String)

    var errorDescription: String? {
        switch self {
        case let .missingResource(name):
            return "Could not find resource \(name).json in bundle."
        }
    }
}
```

- Always conform to `LocalizedError` for user-facing error messages.
- Use `throw` with specific error types, not generic `NSError`.

### ViewModels

```swift
@MainActor
final class ExploreViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var errorMessage: String?

    private let catalog: any CatalogProviding

    func load() async {
        guard phase != .loading else { return }
        phase = .loading

        do {
            let feed = try await catalog.fetchHomeFeed()
            self.feed = feed
            phase = .loaded
        } catch is CancellationError {
            phase = .idle
        } catch {
            errorMessage = error.localizedDescription
            phase = .failed
        }
    }
}
```

- Mark class `final` unless subclassing.
- Use `@MainActor` for all view models.
- Use `@Published` for observable state.
- Use `private(set)` for read-only published properties.
- Implement Phase state machine: `idle → loading → loaded | failed`.
- Check `Task.isCancelled` and catch `CancellationError` separately.

### Repository Pattern

```swift
enum CatalogSource {
    case bundled(fileName: String, bundle: Bundle)
    case rawData(Data)
}

actor CatalogRepository: CatalogProviding {
    private let source: CatalogSource
    private var cachedFeed: HomeFeed?

    init(source: CatalogSource = .bundled(fileName: "mock_catalog", bundle: .main)) {
        self.source = source
    }

    func fetchHomeFeed() async throws -> HomeFeed {
        if let cachedFeed {
            return cachedFeed
        }
        // ... implementation
    }
}
```

- Protocol (Sendable) defines boundary.
- Actor implements with caching.
- Source enum for dependency injection (`.bundled` vs `.rawData`).
- Check cancellation with `Task.isCancelled` before expensive operations.

### Naming Conventions

- **Types/Enums**: `PascalCase` (e.g., `ExploreViewModel`, `Phase`)
- **Properties/Variables**: `camelCase` (e.g., `selectedBook`, `phase`)
- **Constants**: `camelCase` with meaningful names (e.g., `maxRetryCount`)
- **Files**: `PascalCase.swift` matching the primary type (e.g., `ExploreView.swift`)
- **Accessibility IDs**: `screen.{name}`, `novel_detail.tab.{name}`, `reader.{element}`

### Tests

```swift
private struct StubCatalogProvider: CatalogProviding {
    let operation: @Sendable () async throws -> HomeFeed

    func fetchHomeFeed() async throws -> HomeFeed {
        try await operation()
    }
}

final class ExploreViewModelTests: XCTestCase {
    static let sampleFeed = HomeFeed(/* ... */)

    func testLoadSuccess() async throws {
        let provider = StubCatalogProvider {
            return Self.sampleFeed
        }

        let viewModel = await MainActor.run {
            ExploreViewModel(catalog: provider)
        }

        await viewModel.load()

        let phase = await MainActor.run { viewModel.phase }
        XCTAssertEqual(phase, .loaded)
    }
}
```

- Private stub structs implementing protocols.
- Inline `static let` sample data - no shared fixtures.
- Use `MainActor.run` to access @MainActor properties.
- Test file naming: `{ClassName}Tests.swift`.

### SwiftUI Views

```swift
struct ExploreView: View {
    @StateObject private var viewModel: ExploreViewModel
    @State private var selectedBook: Book?

    init(viewModel: @autoclosure @escaping () -> ExploreViewModel = ExploreViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Layout.sectionSpacing) {
                    stateContent
                }
            }
            .task {
                await viewModel.load()
            }
            .navigationDestination(item: $selectedBook) { book in
                NovelDetailView(book: book)
            }
            .accessibilityIdentifier("screen.explore")
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.phase {
        case .idle, .loading:
            ProgressView()
        case .loaded:
            loadedContent
        case .failed:
            failedContent
        }
    }
}
```

- Use `@autoclosure @escaping` for optional view model injection.
- Prefer `@ViewBuilder` for computed view properties.
- Use `navigationDestination(item:)` for type-safe navigation.
- Include accessibility identifiers for all screens.

### Localization

- UI strings use `AppLocalization.string("Key")`.
- Vietnamese strings used for Reader panel and NovelDetail headers.
- Keep consistent when adding new labels.

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

MCP health check (February 13, 2026): `mcp__xcode__XcodeListWindows` returned a valid workspace tab (`windowtab3`), so treat Xcode MCP as available by default.

Use the `mcp__xcode__*` toolset as the first choice for Xcode-aware validation workflows. Use shell + `apply_patch` as the default editing path for code/text changes.

### MCP-First Decision Rule

1. If the task needs compile, tests, diagnostics, previews, Issue Navigator, or runtime snippet execution, use MCP first.
2. If the task is pure file search/edit with no Xcode runtime context, shell tools are fine (`rg`, `sed`, `cat`, `apply_patch`).
3. If shell-only debugging stalls, switch immediately to MCP build/test/diagnostics instead of continuing blind edits.

### Default Authoring Loop (Team Agreement)

1. Read/search using shell (`rg`, `sed`, `cat`) or MCP discovery tools.
2. Edit code with shell + `apply_patch` by default.
3. Always validate with MCP: `BuildProject` -> targeted `RunSomeTests` -> diagnostics (`XcodeListNavigatorIssues` / `XcodeRefreshCodeIssuesInFile`).
4. For UI changes, always capture verification output:
   - `RenderPreview` for SwiftUI preview snapshot verification
   - `xcrun simctl io booted screenshot <output-path>` for live simulator screenshot verification when runtime UI state matters
5. Use MCP edit tools only when project navigator structure must be changed (`XcodeMakeDir`, `XcodeMV`, `XcodeRM`) or when Xcode-context write operations are specifically needed.

### Standard MCP Execution Sequence

1. **Bootstrap context**:
   - `mcp__xcode__XcodeListWindows` to get `tabIdentifier`
   - `mcp__xcode__XcodeLS`, `mcp__xcode__XcodeGlob`, `mcp__xcode__XcodeGrep` to map files/symbols
2. **Implement and validate compile state**:
   - Make edits with shell + `apply_patch` by default (or MCP edit tools when navigator-aware editing is required)
   - `mcp__xcode__BuildProject`
   - `mcp__xcode__GetBuildLog` if build fails
3. **Run the narrowest tests that cover the change**:
   - `mcp__xcode__GetTestList` to discover identifiers
   - `mcp__xcode__RunSomeTests` for targeted checks
   - `mcp__xcode__RunAllTests` for broad/refactor changes
4. **Inspect diagnostics and UI/runtime behavior**:
   - `mcp__xcode__XcodeListNavigatorIssues` for workspace-visible issues
   - `mcp__xcode__XcodeRefreshCodeIssuesInFile` for file-specific diagnostics
   - `mcp__xcode__RenderPreview` for SwiftUI UI validation
   - `mcp__xcode__ExecuteSnippet` for focused runtime probing

### High-Value MCP Patterns

1. **UI change**: `BuildProject` -> `RenderPreview` -> targeted UI test.
2. **Compiler error loop**: `BuildProject` -> `GetBuildLog` -> fix -> rebuild until clean.
3. **Flaky behavior investigation**: `RunSomeTests` -> `XcodeListNavigatorIssues` -> `ExecuteSnippet` in affected file.
4. **Project structure edits**: `XcodeMakeDir`/`XcodeMV`/`XcodeRM` when navigator structure matters.

### Screenshot + Debug Quick Reference

- `mcp__xcode__RenderPreview` is the primary tool for auto-capturing SwiftUI preview snapshots.
- Use `mcp__xcode__DocumentationSearch` to query official Apple Developer docs before/while implementing new APIs.
- Use `mcp__xcode__BuildProject` + `mcp__xcode__GetBuildLog` for compile/debug loops.
- Use `mcp__xcode__XcodeListNavigatorIssues` and `mcp__xcode__XcodeRefreshCodeIssuesInFile` for diagnostics.
- Use `mcp__xcode__RunSomeTests` / `mcp__xcode__RunAllTests` and `mcp__xcode__ExecuteSnippet` for runtime debugging.
- There is no direct Xcode MCP tool for live simulator screen capture; use shell fallback: `xcrun simctl io booted screenshot <output-path>`.

### Always-Use Rules

- **Always use the iPhone 17 Pro simulator** for build, test, and run workflows. Do not use any other simulator device unless explicitly requested.
- Use `mcp__xcode__*` tools first when build/test/diagnostic context is needed.
- Use shell + `apply_patch` as the default editing method for text/code changes.
- Use MCP edit tools when Xcode project-structure awareness is needed.
- Call `mcp__xcode__XcodeListWindows` first whenever a `tabIdentifier` is required.
- Always read/search before editing (via Xcode tools or shell tools).
- Always verify changes with MCP before finalizing:
  - `BuildProject` after modifications
  - `RunSomeTests` for changed behavior (and `RunAllTests` for broad refactors)
  - `XcodeListNavigatorIssues` (and `XcodeRefreshCodeIssuesInFile` when file-specific diagnostics are needed)
- For UI changes, always provide screenshot evidence:
  - `RenderPreview` snapshot for previewable screens
  - simulator screenshot via `xcrun simctl io booted screenshot <output-path>` when live runtime UI is being verified
- Always use `xcodegen generate` after `project.yml` changes; never hand-edit `.xcodeproj`.

## Skill Auto-Load Policy

Load `swift-concurrency` at the start of every new chat in this repo.

- Skill path: `.agents/skills/swift-concurrency/SKILL.md`
- Default behavior:
  - Read and apply its guidance before making Swift code changes.
  - Confirm concurrency settings from `project.yml` first (`SWIFT_VERSION`, `SWIFT_STRICT_CONCURRENCY`) before proposing migration-sensitive fixes.
  - If needed, verify generated settings in `LoveNovel.xcodeproj/project.pbxproj`.
  - Keep Swift 6 strict concurrency compliance (`Sendable`, actor isolation, `@MainActor`, cancellation handling).
  - Treat concurrency safety as a non-optional quality gate.
- Trigger expansion: If a task mentions `async/await`, actors, data races, `Sendable`, `@MainActor`, or Swift 6 migration, apply the skill rules strictly and explicitly in implementation.

### Skill + MCP Coordination Rules

1. Skills decide workflow; MCP executes validation. Do not treat skills as reference-only docs.
2. For Swift code changes, load `swift-concurrency` first, then run MCP validation (`BuildProject`, diagnostics, targeted tests).
3. For API adoption questions, combine skill guidance with `mcp__xcode__DocumentationSearch` before implementing.
4. For UI changes, combine feature/domain skill guidance with `RenderPreview` and relevant UI tests.
5. For PR/CI tasks, use `gh-address-comments` or `gh-fix-ci` for issue intake, then confirm fixes locally with MCP build/tests.
6. If multiple skills apply, use smallest useful set and run in this order: domain skill -> workflow skill -> validation via MCP.

### Skill-to-MCP Quick Matrix

| Scenario | Skill | Required MCP checks |
|----------|-------|---------------------|
| Swift concurrency change | `swift-concurrency` | `BuildProject`, `XcodeRefreshCodeIssuesInFile`, targeted `RunSomeTests` |
| SwiftUI UI update | relevant feature skill + `swift-concurrency` (if state/isolation affected) | `BuildProject`, `RenderPreview`, targeted UI tests |
| New framework/API usage | `swift-concurrency` when async/isolation is involved | `DocumentationSearch`, `BuildProject`, targeted tests |
| PR comment fixes | `gh-address-comments` | `BuildProject`, targeted `RunSomeTests`, `XcodeListNavigatorIssues` |
| Failing GitHub Actions checks | `gh-fix-ci` | Reproduce locally with `BuildProject` + scoped tests before finalizing |

## Commits

Imperative, scoped: `feat:`, `fix:`, `test:`, `refactor:`. One logical change per commit.
PRs: summary + test evidence + screenshots for UI changes. Flag `project.yml` changes.
