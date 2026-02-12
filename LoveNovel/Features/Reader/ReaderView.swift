import SwiftUI

private enum ReaderStorageKey {
    static let didShowTutorial = "reader.didShowTutorial"
}

struct ReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(ReaderStorageKey.didShowTutorial) private var didShowTutorial: Bool = false
    @StateObject private var viewModel: ReaderViewModel
    private let onClose: (() -> Void)?

    init(book: Book, initialChapter: BookChapter, chapterCount: Int, onClose: (() -> Void)? = nil) {
        let hasSeenTutorial = UserDefaults.standard.bool(forKey: ReaderStorageKey.didShowTutorial)
        self.onClose = onClose
        _viewModel = StateObject(
            wrappedValue: ReaderViewModel(
                book: book,
                initialChapter: initialChapter,
                chapterCount: chapterCount,
                shouldShowTutorial: !hasSeenTutorial
            )
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            readerBackgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                chapterContent
            }

            if viewModel.isControlPanelVisible {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 128)
                        .allowsHitTesting(false)

                    Color.black.opacity(0.36)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.dismissControlPanel()
                            }
                        }
                }
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(1)

                bottomPanel
                    .zIndex(2)
            }

            if viewModel.isTutorialVisible {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .zIndex(3)

                tutorialOverlay
                    .zIndex(4)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isControlPanelVisible)
        .alert(
            "Coming Soon",
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.dismissAlert()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.dismissAlert()
            }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                if let onClose {
                    onClose()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(readerPrimaryTextColor)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("reader.back")

            Text(viewModel.chapterTrailTitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(readerSecondaryTextColor)
                .lineLimit(1)

            Spacer()

            if !viewModel.isTutorialVisible {
                Text(viewModel.chapterProgressPercent)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(readerSecondaryTextColor)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.showSettingsPanel()
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(readerPrimaryTextColor)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("reader.top.settings")
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var chapterContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                Text(viewModel.chapterTitle)
                    .font(readerFont(size: viewModel.fontSize + 3, weight: .medium))
                    .foregroundStyle(readerPrimaryTextColor)

                ForEach(Array(viewModel.readingParagraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(readerFont(size: viewModel.fontSize, weight: .regular))
                        .foregroundStyle(readerPrimaryTextColor)
                        .lineSpacing(viewModel.lineSpacing)
                }
            }
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.top, 6)
            .padding(.bottom, 120)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.toggleControlPanelFromCenterTap()
            }
        }
        .accessibilityIdentifier("reader.content")
    }

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                ForEach(ReaderViewModel.PanelTab.allCases) { tab in
                    Button {
                        viewModel.setPanelTab(tab)
                    } label: {
                        VStack(spacing: 10) {
                            Text(tab.rawValue)
                                .font(.system(size: 16, weight: viewModel.selectedPanelTab == tab ? .semibold : .regular))
                                .foregroundStyle(viewModel.selectedPanelTab == tab ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)

                            Rectangle()
                                .fill(viewModel.selectedPanelTab == tab ? AppTheme.Colors.textPrimary : .clear)
                                .frame(height: 3)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(tab == .info ? "reader.panel.tab.info" : "reader.panel.tab.settings")
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.dismissControlPanel()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.top, 14)

            Group {
                if viewModel.selectedPanelTab == .info {
                    panelInfoContent
                } else {
                    panelSettingsContent
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: panelBodyHeight, alignment: .top)
            .clipped()
        }
        .padding(.bottom, 28)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(AppTheme.Colors.screenBackground)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var panelInfoContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(spacing: 16) {
                Text(viewModel.chapterPositionText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                HStack(spacing: 12) {
                    Button {
                        viewModel.moveChapter(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    }
                    .buttonStyle(.plain)

                    Slider(
                        value: Binding(
                            get: { Double(viewModel.currentChapterIndex) },
                            set: { viewModel.updateChapterSlider(to: $0) }
                        ),
                        in: 1...Double(viewModel.totalChapters),
                        step: 1
                    )
                    .tint(AppTheme.Colors.accentBlue)

                    Button {
                        viewModel.moveChapter(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 28) {
                    quickAction(icon: "list.bullet", title: "D.S Chương")
                    quickAction(icon: "textformat", title: "Tự động")
                    quickAction(icon: "bookmark", title: "Đánh dấu")
                    quickAction(icon: "headphones", title: "Nghe")
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.6))
            )

            VStack(spacing: 0) {
                panelActionRow(icon: "arrow.clockwise", title: "Tải lại nội dung")
                panelActionRow(icon: "text.bubble", title: "Bình luận (15)")
                panelActionRow(icon: "book", title: "Thông tin truyện")
                panelActionRow(icon: "arrow.down.circle", title: "Tải truyện")
                panelActionRow(icon: "flag", title: "Báo lỗi")
            }
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
        .padding(.top, 14)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var panelSettingsContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Chế độ đọc")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                HStack(spacing: 0) {
                    ForEach(ReaderViewModel.ReadingMode.allCases) { mode in
                        Button {
                            viewModel.setReadingMode(mode)
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: mode == .paged ? "rectangle.grid.1x2" : "text.justify")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(mode.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(viewModel.selectedReadingMode == mode ? .white : AppTheme.Colors.accentBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(viewModel.selectedReadingMode == mode ? AppTheme.Colors.accentBlue : .clear)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 40)
                .overlay(
                    Capsule()
                        .stroke(AppTheme.Colors.accentBlue, lineWidth: 1.1)
                )
                .clipShape(Capsule())

                Text("Cỡ chữ")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                HStack(spacing: 10) {
                    Text("A")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Slider(value: $viewModel.fontSize, in: 18...32, step: 1)
                        .tint(AppTheme.Colors.accentBlue)

                    Text("A")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .minimumScaleFactor(0.6)
                }
                .padding(.horizontal, 9)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.5))
                )

                Text("Màu")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                HStack(spacing: 5) {
                    ForEach(ReaderViewModel.ReaderThemeStyle.allCases) { theme in
                        Button {
                            viewModel.setTheme(theme)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(themeColor(for: theme))
                                    .frame(width: 24, height: 24)

                                Circle()
                                    .stroke(
                                        viewModel.selectedTheme == theme ? AppTheme.Colors.accentBlue : Color.black.opacity(0.18),
                                        lineWidth: viewModel.selectedTheme == theme ? 2.2 : 1.2
                                    )
                                    .frame(width: 24, height: 24)

                                if viewModel.selectedTheme == theme {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(theme == .charcoal || theme == .black ? .white : AppTheme.Colors.accentBlue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Font chữ")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                VStack(spacing: 2) {
                    ForEach(viewModel.availableFonts, id: \.self) { fontName in
                        Button {
                            viewModel.setFont(fontName)
                        } label: {
                            HStack {
                                Text(fontName)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(AppTheme.Colors.textPrimary)

                                Spacer()

                                if viewModel.selectedFontName == fontName {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(AppTheme.Colors.textPrimary)
                                }
                            }
                            .padding(.horizontal, 9)
                            .frame(height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedFontName == fontName ? Color.white.opacity(0.5) : .clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func quickAction(icon: String, title: String) -> some View {
        Button {
            viewModel.didTapPanelAction(title)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func panelActionRow(icon: String, title: String) -> some View {
        Button {
            viewModel.didTapPanelAction(title)
        } label: {
            HStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.mutedIcon)
                    .frame(width: 30)

                Text(title)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Spacer()
            }
            .padding(.vertical, 15)
        }
        .buttonStyle(.plain)
    }

    private var tutorialOverlay: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 46) {
                tutorialLine(
                    text: "Ấn giữa màn hình để xem thông tin và cài đặt chế độ đọc truyện",
                    icon: "hand.tap.fill"
                )

                tutorialLine(
                    text: "Cuộn lên xuống để hiển thị thêm nội dung",
                    icon: "hand.draw.fill"
                )

                Button {
                    didShowTutorial = true
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.acknowledgeTutorial()
                    }
                } label: {
                    Text("ĐÃ HIỂU")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.black))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("reader.tutorial.dismiss")
            }
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.top, 34)
            .padding(.bottom, 22)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(AppTheme.Colors.screenBackground)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private func tutorialLine(text: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(text)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineSpacing(3)

            Spacer(minLength: 10)

            Image(systemName: icon)
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(AppTheme.Colors.accentBlue)
        }
    }

    private var panelBodyHeight: CGFloat {
        460
    }

    private var readerBackgroundColor: Color {
        switch viewModel.selectedTheme {
        case .light:
            return AppTheme.Colors.readerBackground
        case .coolGray:
            return Color(red: 0.91, green: 0.92, blue: 0.94)
        case .pink:
            return Color(red: 0.92, green: 0.88, blue: 0.89)
        case .ivory:
            return Color(red: 0.92, green: 0.91, blue: 0.86)
        case .sepia:
            return Color(red: 0.72, green: 0.68, blue: 0.60)
        case .warmGray:
            return Color(red: 0.70, green: 0.66, blue: 0.64)
        case .charcoal:
            return Color(red: 0.19, green: 0.20, blue: 0.23)
        case .black:
            return .black
        }
    }

    private var readerPrimaryTextColor: Color {
        switch viewModel.selectedTheme {
        case .charcoal, .black:
            return .white.opacity(0.92)
        default:
            return AppTheme.Colors.textPrimary
        }
    }

    private var readerSecondaryTextColor: Color {
        switch viewModel.selectedTheme {
        case .charcoal, .black:
            return .white.opacity(0.55)
        default:
            return AppTheme.Colors.textSecondary
        }
    }

    private func themeColor(for theme: ReaderViewModel.ReaderThemeStyle) -> Color {
        switch theme {
        case .light:
            return Color(red: 0.96, green: 0.97, blue: 0.98)
        case .coolGray:
            return Color(red: 0.90, green: 0.91, blue: 0.94)
        case .pink:
            return Color(red: 0.90, green: 0.86, blue: 0.86)
        case .ivory:
            return Color(red: 0.90, green: 0.89, blue: 0.83)
        case .sepia:
            return Color(red: 0.72, green: 0.68, blue: 0.60)
        case .warmGray:
            return Color(red: 0.71, green: 0.67, blue: 0.65)
        case .charcoal:
            return Color(red: 0.16, green: 0.16, blue: 0.19)
        case .black:
            return .black
        }
    }

    private func readerFont(size: CGFloat, weight: Font.Weight) -> Font {
        switch viewModel.selectedFontName {
        case "Avenir Next", "Arial", "Helvetica", "Palatino":
            return .custom(viewModel.selectedFontName, size: size).weight(weight)
        default:
            return .system(size: size, weight: weight)
        }
    }
}

#Preview {
    NavigationStack {
        ReaderView(
            book: Book(
                id: "rice-tea",
                title: "Rice Tea",
                author: "Julien McArdle",
                summary: "Bạch Mục đối diện một thành phố phủ đầy tín hiệu nhiễu.",
                rating: 4.6,
                accentHex: "1B3B72"
            ),
            initialChapter: BookChapter(
                id: "rice-tea-chapter-1",
                index: 1,
                title: "Chapter 1",
                timestampText: "2020-04-02 00:58"
            ),
            chapterCount: 55
        )
    }
}
