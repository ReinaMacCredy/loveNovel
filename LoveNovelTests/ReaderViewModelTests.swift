import XCTest
@testable import LoveNovel

@MainActor
final class ReaderViewModelTests: XCTestCase {
    func testInitCanShowTutorial() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: true)

        XCTAssertTrue(viewModel.isTutorialVisible)
        XCTAssertEqual(viewModel.currentChapterIndex, 3)
        XCTAssertEqual(viewModel.totalChapters, 55)
    }

    func testAcknowledgeTutorialHidesOverlay() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: true)

        viewModel.acknowledgeTutorial()

        XCTAssertFalse(viewModel.isTutorialVisible)
    }

    func testSettingsButtonFlowShowsSettingsPanel() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.showSettingsPanel()

        XCTAssertTrue(viewModel.isControlPanelVisible)
        XCTAssertEqual(viewModel.selectedPanelTab, .settings)
    }

    func testCenterTapOpensInfoPanelAndSecondTapCloses() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.toggleControlPanelFromCenterTap()
        XCTAssertTrue(viewModel.isControlPanelVisible)
        XCTAssertEqual(viewModel.selectedPanelTab, .info)

        viewModel.toggleControlPanelFromCenterTap()
        XCTAssertFalse(viewModel.isControlPanelVisible)
    }

    func testChapterSliderClampsToBounds() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.updateChapterSlider(to: 0)
        XCTAssertEqual(viewModel.currentChapterIndex, 1)

        viewModel.updateChapterSlider(to: 999)
        XCTAssertEqual(viewModel.currentChapterIndex, 55)
    }

    private static func makeViewModel(shouldShowTutorial: Bool) -> ReaderViewModel {
        ReaderViewModel(
            book: Book(
                id: "rice-tea",
                title: "Rice Tea",
                author: "Julien McArdle",
                summary: "Sample summary",
                rating: 4.6,
                accentHex: "1B3B72"
            ),
            initialChapter: BookChapter(
                id: "rice-tea-chapter-3",
                index: 3,
                title: "Chapter 3",
                timestampText: "2020-04-02 00:58"
            ),
            chapterCount: 55,
            shouldShowTutorial: shouldShowTutorial
        )
    }
}
