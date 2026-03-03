# LoveNovel

An iOS novel reading app for discovering, reading, and managing stories. Built with SwiftUI, Swift 6 strict concurrency, and zero external dependencies.

## Features

- **Explore**: Browse a curated home feed (latest, featured, recommended, similar stories). Filter by story mode. Full-text search across the catalog.
- **Reader**: Scroll or page-flip reading modes. 8 color themes (light through black). Adjustable font, size, and line spacing. Chapter list navigation. First-launch tutorial overlay.
- **Listen**: Text-to-speech playback via Apple TTS, Google Online, or Microsoft Online. Adjustable speed (0.5x--2.0x). Sleep timer.
- **Library**: Reading history and bookmarks. Sort by newest chapter, recently read, or title. Per-book notification muting.
- **Profile**: Language selection (English, Vietnamese, auto-detect). Dark mode control (auto/off/on) with independent light and dark theme choices.
- **Localization**: Full English and Vietnamese string coverage (199 keys each). Runtime language switching.

## Requirements

- Xcode 26+
- iOS 26.0 deployment target
- iPhone simulator or device (iPhone only)
- XcodeGen (`brew install xcodegen`)

## Getting Started

```bash
# Clone and generate the Xcode project
git clone https://github.com/ReinaMacCredy/loveNovel.git && cd loveNovel
xcodegen generate

# Build
xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run all tests
xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Run a single test class
xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:LoveNovelTests/ExploreViewModelTests
```

Always use the **iPhone 17 Pro** simulator. Never hand-edit `.xcodeproj` -- edit `project.yml` then run `xcodegen generate`.

## Architecture

SwiftUI + MVVM + Repository pattern. Swift 6 strict concurrency throughout.

```
View (@State, SwiftUI)
  -> ViewModel (@MainActor class, Phase state machine)
    -> UseCase protocol (Sendable boundary)
      -> Repository (actor, caches data)
        -> Mock JSON (bundled resources)
```

### Key patterns

- **Phase state machine**: All data-loading ViewModels use `LoadPhase` enum: `idle -> loading -> loaded | failed`. Guards `.loading`, early-returns `.loaded`.
- **DI via factory protocols**: `AppFeatureFactory` / `ReaderFeatureFactory` protocols. `AppContainer` is the composition root. Views depend on protocols, not concrete containers.
- **Actor-isolated data layer**: `CatalogRepository` and `BookDetailRepository` are actors. Thread-safe by design.
- **Sendable models**: All domain entities conform to `Sendable`. No `@unchecked` suppressions.

### Concurrency rules

- All models: `Sendable`
- Data layer: `actor` types
- ViewModels: `@MainActor`
- Strict concurrency enabled: `SWIFT_STRICT_CONCURRENCY=complete`

## Project Structure

```
LoveNovel/
  App/              Entry point, tab navigation, localization, settings
  Core/
    Contracts/      Shared protocols and types (LoadPhase, ChapterTitleFormatting)
    DI/             Composition root (AppContainer), factory protocols
  Domain/
    Entities/       Book, BookDetail, BookChapter, HomeFeed, etc.
    Repositories/   CatalogProviding, BookDetailProviding protocols
    UseCases/       Business logic grouped by feature
  Data/             Actor-based repository implementations, JSON loading
  Presentation/
    Features/
      Explore/      Home feed, search, all-stories list
      NovelDetail/  Book info, chapters, reviews, comments
      Reader/       Reading view, listen/TTS view
      Library/      History, bookmarks, collection store
      Profile/      Settings, dark mode, language
    Shared/         Reusable UI components (ChapterListOverlay, NovelCoverCard)
    Preview/        Preview factories for SwiftUI previews
  Theme/            AppTheme (colors, layout constants)
  Resources/        Bundled mock JSON (mock_catalog.json, mock_book_details.json)
  en.lproj/         English localization strings
  vi.lproj/         Vietnamese localization strings
```

## Module Targets

| Target | Type | Sources | Dependencies |
|--------|------|---------|-------------|
| LoveNovelCore | Framework | App/ (3 files), Theme/, Core/Contracts/, lproj/ | None |
| LoveNovelDomain | Framework | Domain/ | Core |
| LoveNovelData | Framework | Data/ | Domain |
| LoveNovelPresentation | Framework | Presentation/, RootTabView, FeatureFactories | Core, Domain |
| LoveNovel | Application | App entry point, AppContainer | All above |
| LoveNovelTests | Unit tests | 13 test files | All above |
| LoveNovelUITests | UI tests | 3 test files | LoveNovel (host app) |

## Testing

- **Framework**: Swift Testing (`@Test`, `#expect`, `#require`)
- **Unit tests**: ViewModel tests with stub use-case implementations, repository tests with mock JSON injection, use-case logic tests
- **UI tests**: Tab navigation, feature integration flows
- **Isolation**: Each test class owns inline sample data. No shared fixtures. VM tests use private stub structs with closure injection.

## Constraints

- **No external dependencies**: Pure iOS SDK. No SPM, CocoaPods, or Carthage.
- **XcodeGen**: `project.yml` is the single source of truth for project configuration.
- **Vietnamese UI strings** in Reader and NovelDetail views. Keep consistent when adding labels.
- **iPhone only**: `TARGETED_DEVICE_FAMILY: 1`.

## Commits

Imperative mood, scoped prefixes: `feat:`, `fix:`, `test:`, `refactor:`, `docs:`, `perf:`. One logical change per commit.
