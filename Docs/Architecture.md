# LoveNovel Clean Architecture

This project follows a four-layer structure:

- `Domain`: business entities, repository protocols, and use cases.
- `Data`: concrete repository implementations and data-source concerns.
- `Presentation`: SwiftUI views, feature application use cases, and `@MainActor` view models.
- `Core`: composition and cross-cutting contracts (dependency injection, shared ports).

## Dependency Direction

Use this rule to avoid architecture drift:

- `Presentation` can depend on `Domain` and `Core`.
- `Data` can depend on `Domain`.
- `Core` can depend on `Domain`, `Data`, and `Presentation` only for composition.
- `Domain` must not depend on `Data`, `Presentation`, or `Core`.

## ViewModel Rule

View models must depend on use-case protocols, not repositories directly, and screens should depend on feature-factory protocols instead of concrete containers.

- Allowed: `ExploreViewModel(loadHomeFeedUseCase: ...)`
- Not allowed: `ExploreViewModel(catalogRepository: ...)`
- Allowed: `ExploreView(featureFactory: some ExploreFeatureFactory)`
- Not allowed: `ExploreView(container: AppContainer)` as a concrete dependency

## Composition Root

`Core/DI/AppContainer.swift` is the composition root.

- Construct repositories once.
- Build use-case objects from repositories.
- Provide feature factories (`ExploreFeatureFactory`, `NovelDetailFeatureFactory`, `LibraryFeatureFactory`, `ReaderFeatureFactory`).
- Inject cross-layer ports (for example `ChapterTitleFormatting`) to keep Domain free of App/static globals.
- Keep this as the single place where Data and Presentation are wired together.

## Testing Guidance

- Unit test use-case and view-model behavior with stub protocol implementations.
- Keep UI tests focused on navigation and visible behavior.
- Prefer targeted suites during refactors, then run broader suites before merge.
