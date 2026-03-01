import Testing
@testable import LoveNovelCore
@testable import LoveNovelDomain
@testable import LoveNovelPresentation

private struct StubReaderChapterTitleFormatter: ChapterTitleFormatting {
    func chapterTitle(for index: Int) -> String {
        "Chapter \(index)"
    }
}

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

    @Test("Listen quick action flow toggles settings and source list")
    func listenQuickActionFlowTogglesSettingsAndSourceList() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.showListenSettings()
        #expect(viewModel.isListenSettingsVisible)
        #expect(viewModel.isListenSourceListVisible == false)

        viewModel.toggleListenSourceList()
        #expect(viewModel.isListenSourceListVisible)

        viewModel.setListenSource(.microsoftOnline)
        #expect(viewModel.selectedListenSource == .microsoftOnline)
        #expect(viewModel.isListenSourceListVisible == false)

        viewModel.dismissListenSettings()
        #expect(viewModel.isListenSettingsVisible == false)
    }

    @Test("Sleep timer dialog applies valid minutes")
    func sleepTimerDialogAppliesValidMinutes() throws {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.showSleepTimerDialog()
        #expect(viewModel.isSleepTimerDialogVisible)

        viewModel.sleepTimerInputMinutes = "25"
        viewModel.confirmSleepTimer()

        #expect(viewModel.isSleepTimerDialogVisible == false)
        #expect(try #require(viewModel.sleepTimerMinutes) == 25)
    }

    @Test("Sleep timer rejects invalid minutes and keeps dialog open")
    func sleepTimerRejectsInvalidMinutesAndKeepsDialogOpen() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.showSleepTimerDialog()
        viewModel.sleepTimerInputMinutes = "500"
        viewModel.confirmSleepTimer()

        #expect(viewModel.isSleepTimerDialogVisible)
        #expect(viewModel.sleepTimerMinutes == nil)
        #expect(viewModel.alertMessage != nil)
    }

    @Test("Toggle playback flips isPlaying")
    func togglePlaybackFlipsIsPlaying() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        #expect(viewModel.isPlaying == false)

        viewModel.togglePlayback()
        #expect(viewModel.isPlaying)

        viewModel.togglePlayback()
        #expect(viewModel.isPlaying == false)
    }

    @Test("Show listen page sets visible and hides control panel")
    func showListenPageSetsVisibleAndHidesControlPanel() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.toggleControlPanelFromCenterTap()
        #expect(viewModel.isControlPanelVisible)

        viewModel.showListenPage()
        #expect(viewModel.isListenPageVisible)
        #expect(viewModel.isControlPanelVisible == false)
    }

    @Test("Dismiss listen page resets isPlaying")
    func dismissListenPageResetsIsPlaying() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: false)

        viewModel.showListenPage()
        viewModel.togglePlayback()
        #expect(viewModel.isPlaying)

        viewModel.dismissListenPage()
        #expect(viewModel.isListenPageVisible == false)
        #expect(viewModel.isPlaying == false)
    }

    @Test("Show listen page blocked during tutorial")
    func showListenPageBlockedDuringTutorial() {
        let viewModel = Self.makeViewModel(shouldShowTutorial: true)

        viewModel.showListenPage()
        #expect(viewModel.isListenPageVisible == false)
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
            shouldShowTutorial: shouldShowTutorial,
            buildChapterUseCase: DefaultBuildReaderChapterUseCase(
                chapterTitleFormatter: StubReaderChapterTitleFormatter()
            )
        )
    }
}
