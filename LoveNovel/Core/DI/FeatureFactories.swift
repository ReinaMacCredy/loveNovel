import Foundation
import LoveNovelDomain

public protocol ExploreFeatureFactory: Sendable {
    @MainActor
    func makeExploreViewModel() -> ExploreViewModel
}

public protocol NovelDetailFeatureFactory: Sendable {
    @MainActor
    func makeNovelDetailViewModel(book: Book) -> NovelDetailViewModel
}

public protocol LibraryFeatureFactory: Sendable {
    @MainActor
    func makeLibraryViewModel() -> LibraryViewModel
}

public protocol ReaderFeatureFactory: Sendable {
    @MainActor
    func makeReaderViewModel(
        book: Book,
        initialChapter: BookChapter,
        chapterCount: Int,
        chapters: [BookChapter],
        shouldShowTutorial: Bool
    ) -> ReaderViewModel
}

public typealias AppFeatureFactory = ExploreFeatureFactory
    & NovelDetailFeatureFactory
    & LibraryFeatureFactory
    & ReaderFeatureFactory
