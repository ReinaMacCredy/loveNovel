# Repository Guidelines

## Project Structure & Module Organization
- `LoveNovel/` is organized by Clean Architecture layers and built as separate targets:
  - `LoveNovelCore`: shared app settings/localization/theme/contracts.
  - `LoveNovelDomain`: entities, repository protocols, and use cases.
  - `LoveNovelData`: actor-based repository implementations and data sources.
  - `LoveNovelPresentation`: SwiftUI screens/components and `@MainActor` view models.
  - App shell target `LoveNovel` composes features through centralized DI (`Core/DI/AppContainer.swift`).
- Supporting folders: `App/` (app shell), `Theme/`, `Resources/`, `en.lproj/`, `vi.lproj/`.
- Tests:
  - `LoveNovelTests/` for unit/integration logic.
  - `LoveNovelUITests/` for UI/navigation behavior.
- Project configuration:
  - `project.yml` is the source of truth.
  - `Docs/Architecture.md` defines dependency direction and layering rules.

## Build, Test, and Development Commands
- `xcodegen generate` regenerates `LoveNovel.xcodeproj` after `project.yml` changes.
- `xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` builds the app.
- `xcodebuild -project LoveNovel.xcodeproj -scheme LoveNovel -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` runs all tests.
- `xcodebuild ... test -only-testing:LoveNovelTests/ExploreViewModelTests` runs a focused suite.

## MCP Tool Playbook
Use `mcp__xcode__XcodeListWindows` first to get the current `tabIdentifier`, then run other `mcp__xcode__*` tools.

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

### Skill + MCP Coordination Rules

1. Skills decide workflow; MCP executes validation. Do not treat skills as reference-only docs.
2. For Swift code changes, load `swiftui-expert-skill` + `core-data-expert` (as applicable) before `swift-concurrency`, then run MCP validation (`BuildProject`, diagnostics, targeted tests).
3. For API adoption questions, combine skill guidance with `mcp__xcode__DocumentationSearch` before implementing.
4. For UI changes, combine feature/domain skill guidance with `RenderPreview` and relevant UI tests.
5. For PR/CI tasks, use `gh-address-comments` or `gh-fix-ci` for issue intake, then confirm fixes locally with MCP build/tests.
6. If multiple skills apply, use smallest useful set and run in this order: domain skill -> workflow skill -> validation via MCP.

### Skill-to-MCP Quick Matrix

| Scenario | Skill | Required MCP checks |
|----------|-------|---------------------|
| Swift concurrency change | `swift-concurrency` (+ domain skill when applicable) | `BuildProject`, `XcodeRefreshCodeIssuesInFile`, targeted `RunSomeTests` |
| SwiftUI UI update | `swiftui-expert-skill` + `swift-concurrency` | `BuildProject`, `RenderPreview`, targeted UI tests |
| Core Data change | `core-data-expert` + `swift-concurrency` | `BuildProject`, `XcodeRefreshCodeIssuesInFile`, targeted `RunSomeTests` |
| New framework/API usage | `swift-concurrency` when async/isolation is involved | `DocumentationSearch`, `BuildProject`, targeted tests |
| PR comment fixes | `gh-address-comments` | `BuildProject`, targeted `RunSomeTests`, `XcodeListNavigatorIssues` |
| Failing GitHub Actions checks | `gh-fix-ci` | Reproduce locally with `BuildProject` + scoped tests before finalizing |

## Coding Style & Naming Conventions
- Follow Swift 6 strict concurrency: `Sendable` models, actors in Data, `@MainActor` view models, and cancellation-aware async code.
- Preserve architecture boundaries: Domain must not depend on Data or Presentation; Core remains dependency-only.
- View models must depend on use-case protocols, not repository implementations.
- Naming: `PascalCase` for types/files, `camelCase` for members, test files as `{TypeName}Tests.swift`.
- Use Xcode default formatting (4-space indentation). No project SwiftLint/SwiftFormat config is enforced.

## Testing Guidelines
- Unit tests use Swift Testing (`import Testing`, `@Test`, `#expect`).
- UI tests use XCTest in `LoveNovelUITests/`.
- Add targeted tests for every behavior change, especially use-case and view-model flows.
- Before opening a PR, run focused tests for touched areas, then full test pass.

## Commit & Pull Request Guidelines
- Use conventional prefixes seen in history: `feat:`, `fix:`, `test:`, `refactor:`, `docs:`, `chore:`.
- Keep each commit to one logical change.
- PRs should include:
  - clear summary and architecture impact,
  - build/test evidence (commands + result),
  - screenshots for UI changes,
  - notes when `project.yml` changed (and regenerated project files).
