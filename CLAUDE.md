# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Reference

See `AGENTS.md` for the full knowledge base: code map, navigation flow, conventions, gotchas, and MCP tool playbook.

## Build Commands

```bash
# Build
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

# Regenerate xcodeproj (required after project.yml changes)
xcodegen generate
```

Always use **iPhone 17 Pro** simulator. Never hand-edit `.xcodeproj` — edit `project.yml` then run `xcodegen generate`.

## Architecture

**SwiftUI + MVVM + Repository pattern. Swift 6 strict concurrency. Zero external dependencies.**

```
View (@State, SwiftUI)
  → ViewModel (@MainActor class, Phase state machine)
    → Protocol (Sendable boundary)
      → Repository (actor, caches data)
        → Mock JSON (bundled resources)
```

- **Phase pattern**: All data-loading VMs use `Phase` enum: `idle → loading → loaded | failed`. Guard `.loading`, early-return `.loaded`.
- **DI via Source enum**: Repositories accept `.bundled` (real JSON) or `.rawData(Data)` (tests).
- **Navigation**: `RootTabView` (3 tabs) → `ExploreView` (NavigationStack) → `NovelDetailView` → `ReaderView`. All via `navigationDestination(item:)`.

## Key Constraints

- **Swift 6 strict concurrency** (`SWIFT_STRICT_CONCURRENCY=complete`): all models `Sendable`, data layer uses `actor`, VMs use `@MainActor`. Fix concurrency warnings — never suppress them.
- **No external dependencies**: no SPM, CocoaPods, or Carthage. Pure iOS SDK.
- **XcodeGen**: `project.yml` is the single source of truth for project configuration.
- **iOS 26.0** deployment target, Swift 6.0.
- **Vietnamese UI strings** in Reader and NovelDetail. Keep consistent when adding labels.
- **Test isolation**: each test class owns inline sample data — no shared fixtures. VM tests use private stub structs with closure injection.

## Xcode MCP Tools

**Prefer Xcode MCP tools over raw `xcodebuild` shell commands.** They operate on the Xcode project structure directly — file creation/deletion auto-updates project references without touching `.xcodeproj`.

### Setup

Every tool requires a `tabIdentifier`. Call **XcodeListWindows** first to get it.

### Tool Reference

#### Project Navigation & File Management

| Tool | Purpose | When to Use |
|---|---|---|
| `XcodeListWindows` | Lists open Xcode windows + tab IDs | **Always call first** — every other tool needs the `tabIdentifier` |
| `XcodeLS` | Lists files/dirs in the project navigator | Browse project structure, see contents of a group |
| `XcodeGlob` | Finds files by wildcard pattern (`**/*.swift`) | Locate files by name across the project |
| `XcodeGrep` | Searches file contents with regex | Find usages, definitions, string matches in code |
| `XcodeRead` | Reads file contents with line numbers | Read source before editing |

#### File Editing & Creation

| Tool | Purpose | When to Use |
|---|---|---|
| `XcodeWrite` | Creates or overwrites a file, auto-adds to project | Create new source files — automatically added to Xcode project |
| `XcodeUpdate` | Replaces a specific string in a file | Edit existing code (project-aware `Edit`) |
| `XcodeMakeDir` | Creates directories/groups in project | Add new folders/groups for code organization |
| `XcodeMV` | Moves or copies files within project | Rename or reorganize while keeping project references |
| `XcodeRM` | Removes files/dirs from project (optionally disk) | Delete files — cleans both project reference and filesystem |

#### Building & Diagnostics

| Tool | Purpose | When to Use |
|---|---|---|
| `BuildProject` | Builds project, waits for completion | Verify compilation after changes |
| `GetBuildLog` | Gets build log filtered by severity/pattern | Inspect errors/warnings after a failed build |
| `XcodeListNavigatorIssues` | Lists issues from Xcode's Issue Navigator | See all current errors/warnings in workspace |
| `XcodeRefreshCodeIssuesInFile` | Gets live compiler diagnostics for one file | Quick single-file error check without full build |

#### Testing

| Tool | Purpose | When to Use |
|---|---|---|
| `GetTestList` | Lists all tests from active test plan | Discover available tests before running |
| `RunAllTests` | Runs every test in active test plan | Full test suite verification |
| `RunSomeTests` | Runs specific tests by target + identifier | Run only tests relevant to your change |

#### Previews, Execution & Docs

| Tool | Purpose | When to Use |
|---|---|---|
| `RenderPreview` | Builds and snapshots a SwiftUI `#Preview` | Visually verify UI without launching simulator |
| `ExecuteSnippet` | Runs code snippet in context of a source file | Quick experiments — test logic, print values, prototype |
| `DocumentationSearch` | Searches Apple Developer Documentation | Look up Apple APIs, frameworks, usage patterns |

### Typical Workflow

```
1. XcodeListWindows        → get tabIdentifier
2. XcodeLS / Glob / Grep   → explore project
3. XcodeRead               → read file to change
4. XcodeUpdate / XcodeWrite → make changes
5. BuildProject            → verify compilation
6. GetBuildLog             → check errors if build fails
7. RunSomeTests            → run relevant tests
8. RenderPreview           → verify UI visually (if applicable)
```

## Commits

Imperative, scoped prefixes: `feat:`, `fix:`, `test:`, `refactor:`, `docs:`. One logical change per commit.
