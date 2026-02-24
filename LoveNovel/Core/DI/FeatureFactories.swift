import Foundation
import LoveNovelDomain

protocol ExploreFeatureFactory: Sendable {
    @MainActor
    func makeExploreViewModel() -> ExploreViewModel
}

protocol NovelDetailFeatureFactory: Sendable {
    @MainActor
    func makeNovelDetailViewModel(book: Book) -> NovelDetailViewModel
}

protocol LibraryFeatureFactory: Sendable {
    @MainActor
    func makeLibraryViewModel() -> LibraryViewModel
}

protocol ReaderFeatureFactory: Sendable {
    @MainActor
    func makeReaderViewModel(
        book: Book,
        initialChapter: BookChapter,
        chapterCount: Int,
        chapters: [BookChapter],
        shouldShowTutorial: Bool
    ) -> ReaderViewModel
}

typealias AppFeatureFactory = ExploreFeatureFactory
    & NovelDetailFeatureFactory
    & LibraryFeatureFactory
    & ReaderFeatureFactory
