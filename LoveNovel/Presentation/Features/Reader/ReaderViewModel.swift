import CoreGraphics
import SwiftUI
import LoveNovelCore
import LoveNovelDomain

@MainActor
final class ReaderViewModel: ObservableObject {
    enum PanelTab: String, CaseIterable, Identifiable {
        case info = "Thông tin"
        case settings = "Cài đặt"

        var id: Self { self }

        var titleKey: LocalizedStringKey {
            LocalizedStringKey(rawValue)
        }
    }

    enum ReadingMode: String, CaseIterable, Identifiable {
        case paged = "Lật trang"
        case scrolling = "Cuộn đọc"

        var id: Self { self }

        var titleKey: LocalizedStringKey {
            LocalizedStringKey(rawValue)
        }
    }

    enum ReaderThemeStyle: String, CaseIterable, Identifiable {
        case light
        case coolGray
        case pink
        case ivory
        case sepia
        case warmGray
        case charcoal
        case black

        var id: Self { self }
    }

    @Published private(set) var isControlPanelVisible: Bool = false
    @Published private(set) var isChapterListVisible: Bool = false
    @Published private(set) var isTutorialVisible: Bool
    @Published var selectedPanelTab: PanelTab = .info
    @Published var selectedReadingMode: ReadingMode = .scrolling
    @Published var selectedTheme: ReaderThemeStyle = .light
    @Published var selectedFontName: String = "Avenir Next"
    @Published var currentChapterIndex: Int
    @Published var fontSize: CGFloat = 24
    @Published var lineSpacing: CGFloat = 10
    @Published var alertMessage: String?

    let book: Book
    let totalChapters: Int
    let availableFonts: [String] = ["Avenir Next", "Arial", "Helvetica", "Palatino"]
    private let buildChapterUseCase: any BuildReaderChapterUseCase
    private let chapterTimestampText: String
    private let providedChaptersByIndex: [Int: BookChapter]?

    init(
        book: Book,
        initialChapter: BookChapter,
        chapterCount: Int,
        chapters: [BookChapter] = [],
        shouldShowTutorial: Bool,
        buildChapterUseCase: any BuildReaderChapterUseCase
    ) {
        self.book = book
        self.buildChapterUseCase = buildChapterUseCase
        let maxProvidedChapterIndex = chapters.map(\.index).max() ?? 0
        let normalizedTotalChapters = max(chapterCount, maxProvidedChapterIndex, 1)
        self.totalChapters = normalizedTotalChapters
        self.chapterTimestampText = initialChapter.timestampText
        self.currentChapterIndex = Self.clampChapterIndex(initialChapter.index, total: normalizedTotalChapters)
        self.isTutorialVisible = shouldShowTutorial

        let validProvidedChapters = chapters
            .filter { chapter in
                chapter.index >= 1 && chapter.index <= normalizedTotalChapters
            }
            .reduce(into: [Int: BookChapter]()) { partialResult, chapter in
                partialResult[chapter.index] = chapter
            }

        if validProvidedChapters.isEmpty {
            self.providedChaptersByIndex = nil
        } else {
            self.providedChaptersByIndex = validProvidedChapters
        }
    }

    var chapterTrailTitle: String {
        AppLocalization.format("reader.chapter.trail_title", paddedChapterIndex, book.title)
    }

    var chapterTitle: String {
        AppLocalization.format("reader.chapter.title", paddedChapterIndex, book.title)
    }

    var chapterProgressPercent: String {
        let progress = Int((Double(currentChapterIndex) / Double(totalChapters)) * 100)
        return "\(progress)%"
    }

    var chapterPositionText: String {
        "\(currentChapterIndex) / \(totalChapters)"
    }

    var currentChapter: BookChapter {
        chapter(for: currentChapterIndex)
    }

    var readingParagraphs: [String] {
        [
            "\(book.summary)",
            "Bạch Mục tựa lưng vào bức tường lạnh, nghe tiếng kim loại va vào nhau ngoài hành lang. Cậu hít sâu, giữ nhịp tim chậm lại để đọc vị mọi chuyển động trong bóng tối.",
            "Mỗi bước chân tiến gần đều khiến không khí đặc quánh. Những ký hiệu trên thiết bị liên lạc chớp tắt liên tục, báo rằng mạng lưới đang bị can thiệp từ một nguồn chưa xác định.",
            "Cậu kéo chiếc ghế sắt về phía mái hiên, châm ngọn lửa nhỏ để giữ tầm nhìn. Trong tiếng mưa, những mảnh ký ức rời rạc ghép lại thành một câu hỏi lớn hơn cả nhiệm vụ hiện tại.",
            "Đến khi bản đồ số mở ra trước mắt, Bạch Mục mới nhận ra tuyến đường thoát duy nhất nằm ngay giữa vùng cấm. Nếu chậm thêm một nhịp, mọi dữ liệu sẽ bị xóa sạch.",
            "Cậu đứng dậy, siết chặt chiếc máy phát tín hiệu, rồi bước vào màn đêm. Phía trước là một thành phố đang ngủ, phía sau là toàn bộ bí mật vừa được đánh thức."
        ]
    }

    var chapterList: [BookChapter] {
        (1...totalChapters).map(chapter(for:))
    }

    func toggleControlPanelFromCenterTap() {
        guard !isTutorialVisible else {
            return
        }

        if isControlPanelVisible {
            isControlPanelVisible = false
        } else {
            selectedPanelTab = .info
            isControlPanelVisible = true
        }
    }

    func showSettingsPanel() {
        guard !isTutorialVisible else {
            return
        }

        selectedPanelTab = .settings
        isControlPanelVisible = true
    }

    func dismissControlPanel() {
        isControlPanelVisible = false
    }

    func showChapterList() {
        guard !isTutorialVisible else {
            return
        }

        isControlPanelVisible = false
        isChapterListVisible = true
    }

    func dismissChapterList() {
        isChapterListVisible = false
    }

    func setPanelTab(_ tab: PanelTab) {
        selectedPanelTab = tab
    }

    func setReadingMode(_ mode: ReadingMode) {
        selectedReadingMode = mode
    }

    func setTheme(_ theme: ReaderThemeStyle) {
        selectedTheme = theme
    }

    func setFont(_ font: String) {
        selectedFontName = font
    }

    func acknowledgeTutorial() {
        isTutorialVisible = false
    }

    func updateChapterSlider(to value: Double) {
        currentChapterIndex = Self.clampChapterIndex(Int(value.rounded()), total: totalChapters)
    }

    func moveChapter(by step: Int) {
        currentChapterIndex = Self.clampChapterIndex(currentChapterIndex + step, total: totalChapters)
    }

    func jumpToChapter(_ chapterIndex: Int) {
        currentChapterIndex = Self.clampChapterIndex(chapterIndex, total: totalChapters)
        isChapterListVisible = false
    }

    func didTapPanelAction(_ title: String) {
        alertMessage = AppLocalization.format("reader.panel.action.coming_soon", title)
    }

    func dismissAlert() {
        alertMessage = nil
    }

    private var paddedChapterIndex: String {
        String(format: "%02d", currentChapterIndex)
    }

    private func chapter(for index: Int) -> BookChapter {
        buildChapterUseCase.execute(
            bookID: book.id,
            chapterIndex: index,
            chapterTimestampText: chapterTimestampText,
            providedChapter: providedChaptersByIndex?[index]
        )
    }

    private static func clampChapterIndex(_ value: Int, total: Int) -> Int {
        min(max(value, 1), total)
    }
}
