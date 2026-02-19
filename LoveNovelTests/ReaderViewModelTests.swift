import Testing
@testable import LoveNovel

@MainActor
@Suite("Reader view model tests", .tags(.viewModel, .fast))
struct ReaderViewModelTests {
    @Test("Init can show tutorial")
    func initCanShowTutorial() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: true)

        #expect(viewModel.isTutorialVisible)
        #expect(viewModel.currentChapterIndex == 3)
        #expect(viewModel.totalChapters == 55)
    }

    @Test("Acknowledge tutorial hides overlay")
    func acknowledgeTutorialHidesOverlay() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: true)

        viewModel.acknowledgeTutorial()

        #expect(viewModel.isTutorialVisible == false)
    }

    @Test("Settings button flow shows settings panel")
    func settingsButtonFlowShowsSettingsPanel() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.showSettingsPanel()

        #expect(viewModel.isControlPanelVisible)
        #expect(viewModel.selectedPanelTab == .settings)
    }

    @Test("Center tap opens info panel and second tap closes")
    func centerTapOpensInfoPanelAndSecondTapCloses() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.toggleControlPanelFromCenterTap()
        #expect(viewModel.isControlPanelVisible)
        #expect(viewModel.selectedPanelTab == .info)

        viewModel.toggleControlPanelFromCenterTap()
        #expect(viewModel.isControlPanelVisible == false)
    }

    @Test(
        "Chapter slider clamps to bounds",
        arguments: zip([0.0, 999.0], [1, 55])
    )
    func chapterSliderClampsToBounds(input: Double, expectedChapter: Int) {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.updateChapterSlider(to: input)

        #expect(viewModel.currentChapterIndex == expectedChapter)
    }

    @Test("Show chapter list hides panel")
    func showChapterListHidesPanel() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.toggleControlPanelFromCenterTap()
        #expect(viewModel.isControlPanelVisible)

        viewModel.showChapterList()

        #expect(viewModel.isControlPanelVisible == false)
        #expect(viewModel.isChapterListVisible)
    }

    @Test(
        "Jump to chapter clamps and dismisses chapter list",
        arguments: zip([0, 999], [1, 55])
    )
    func jumpToChapterClampsAndDismissesChapterList(input: Int, expectedChapter: Int) {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.showChapterList()
        #expect(viewModel.isChapterListVisible)

        viewModel.jumpToChapter(input)

        #expect(viewModel.currentChapterIndex == expectedChapter)
        #expect(viewModel.isChapterListVisible == false)
    }

    @Test("Provided chapter list overrides generated chapter metadata")
    func providedChapterListOverridesGeneratedChapterMetadata() throws {
        let chapters = [
            BookChapter(
                id: "rice-tea-chapter-1",
                index: 1,
                title: "Chương 1: Mở màn",
                timestampText: "2026-02-17 13:12"
            )
        ]

        let viewModel = Self.makeViewModel(
            shouldShowTutorial: false,
            chapterCount: 3,
            chapters: chapters
        )

        let firstChapter = try #require(viewModel.chapterList.first)
        #expect(firstChapter.title == "Chương 1: Mở màn")
        #expect(firstChapter.timestampText == "2026-02-17 13:12")
    }

    private static func makeViewModel(
        shouldShowTutorial: Bool,
        chapterCount: Int = 55,
        chapters: [BookChapter] = []
    ) -> ReaderViewModel {
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
            chapterCount: chapterCount,
            chapters: chapters,
            shouldShowTutorial: shouldShowTutorial
        )
    }
}
