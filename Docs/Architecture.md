# LoveNovel Clean Architecture

This project follows a four-layer structure:

- `Domain`: business entities, repository protocols, and use cases.
- `Data`: concrete repository implementations and data-source concerns.
- `Presentation`: SwiftUI views and `@MainActor` view models.
- `Core`: composition and cross-cutting app wiring (dependency injection).

## Dependency Direction

Use this rule to avoid architecture drift:

- `Presentation` can depend on `Domain` and `Core`.
- `Data` can depend on `Domain`.
- `Core` can depend on `Domain`, `Data`, and `Presentation` only for composition.
- `Domain` must not depend on `Data`, `Presentation`, or `Core`.

## ViewModel Rule

View models must depend on use-case protocols, not repositories directly.

- Allowed: `ExploreViewModel(loadHomeFeedUseCase: ...)`
- Not allowed: `ExploreViewModel(catalogRepository: ...)`

## Composition Root

`Core/DI/AppContainer.swift` is the composition root.

- Construct repositories once.
- Build use-case objects from repositories.
- Provide factories for presentation-layer view models.
- Keep this as the single place where Data and Presentation are wired together.

## Testing Guidance

- Unit test use-case and view-model behavior with stub protocol implementations.
- Keep UI tests focused on navigation and visible behavior.
- Prefer targeted suites during refactors, then run broader suites before merge.
