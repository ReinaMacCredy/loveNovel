import SwiftUI
import LoveNovelCore
import LoveNovelDomain

private enum ReaderStorageKey {
    static let didShowTutorial = "reader.didShowTutorial"
}

struct ReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(ReaderStorageKey.didShowTutorial) private var didShowTutorial: Bool = false
    @AppStorage(AppSettingsKey.readerDarkMode) private var readerDarkModeRawValue: String = ReaderDarkModeOption.auto.rawValue
    @AppStorage(AppSettingsKey.readerLightTheme) private var readerLightThemeRawValue: String = ReaderViewModel.ReaderThemeStyle.light.rawValue
    @AppStorage(AppSettingsKey.readerDarkTheme) private var readerDarkThemeRawValue: String = ReaderViewModel.ReaderThemeStyle.charcoal.rawValue
    @StateObject private var viewModel: ReaderViewModel
    private let onProgressChange: ((_ chapterIndex: Int, _ totalChapters: Int) -> Void)?
    private let onClose: (() -> Void)?

    init(
        book: Book,
        initialChapter: BookChapter,
        chapterCount: Int,
        chapterList: [BookChapter] = [],
        featureFactory: any ReaderFeatureFactory = PreviewFeatureFactory.live,
        onProgressChange: ((_ chapterIndex: Int, _ totalChapters: Int) -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        let hasSeenTutorial = UserDefaults.standard.bool(forKey: ReaderStorageKey.didShowTutorial)
        self.onProgressChange = onProgressChange
        self.onClose = onClose
        _viewModel = StateObject(
            wrappedValue: featureFactory.makeReaderViewModel(
                book: book,
                initialChapter: initialChapter,
                chapterCount: chapterCount,
                chapters: chapterList,
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
                panelBackdrop
                    .transition(.opacity)
                    .zIndex(1)

                bottomPanel
                    .zIndex(2)
            }

            if viewModel.isChapterListVisible {
                chapterListOverlay
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(5)
            }

            if viewModel.isTutorialVisible {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .zIndex(6)

                tutorialOverlay
                    .zIndex(7)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isControlPanelVisible)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isChapterListVisible)
        .leftEdgeSwipeUpBackGesture {
            closeReader()
        }
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
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            applyThemeFromSettings()
            reportCurrentProgress()
        }
        .onChange(of: colorScheme) { _, _ in
            guard selectedDarkMode == .auto else {
                return
            }

            applyThemeFromSettings()
        }
        .onChange(of: readerDarkModeRawValue) { _, _ in
            applyThemeFromSettings()
        }
        .onChange(of: readerLightThemeRawValue) { _, _ in
            applyThemeFromSettings()
        }
        .onChange(of: readerDarkThemeRawValue) { _, _ in
            applyThemeFromSettings()
        }
        .onChange(of: viewModel.selectedTheme) { _, updatedTheme in
            persistThemeSelection(updatedTheme)
        }
        .onChange(of: viewModel.currentChapterIndex) { _, _ in
            reportCurrentProgress()
        }
    }

    private func closeReader() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                closeReader()
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
        ScrollView(.vertical) {
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
        .scrollIndicators(.hidden)
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
            HStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach(ReaderViewModel.PanelTab.allCases) { tab in
                        Button {
                            viewModel.setPanelTab(tab)
                        } label: {
                            VStack(spacing: 10) {
                                Text(tab.titleKey)
                                    .font(.system(size: 16, weight: viewModel.selectedPanelTab == tab ? .semibold : .regular))
                                    .foregroundStyle(viewModel.selectedPanelTab == tab ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                                    .frame(maxWidth: .infinity)

                                Rectangle()
                                    .fill(viewModel.selectedPanelTab == tab ? AppTheme.Colors.textPrimary : .clear)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 3)
                                    .padding(.horizontal, 18)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(tab == .info ? "reader.panel.tab.info" : "reader.panel.tab.settings")
                    }
                }
                .frame(maxWidth: .infinity)

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

    private var panelBackdrop: some View {
        Color.black.opacity(0.36)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.dismissControlPanel()
                }
            }
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
                    quickAction(
                        icon: "list.bullet",
                        title: "D.S Chương",
                        accessibilityIdentifier: "reader.quick.chapter_list"
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showChapterList()
                        }
                    }
                    quickAction(
                        icon: "textformat",
                        title: "Tự động",
                        accessibilityIdentifier: "reader.quick.auto"
                    ) {
                        viewModel.didTapPanelAction(AppLocalization.string("Tự động"))
                    }
                    quickAction(
                        icon: "bookmark",
                        title: "Đánh dấu",
                        accessibilityIdentifier: "reader.quick.bookmark"
                    ) {
                        viewModel.didTapPanelAction(AppLocalization.string("Đánh dấu"))
                    }
                    quickAction(
                        icon: "headphones",
                        title: "Nghe",
                        accessibilityIdentifier: "reader.quick.listen"
                    ) {
                        viewModel.didTapPanelAction(AppLocalization.string("Nghe"))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.Colors.translucentSurfaceBackground)
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
        ScrollView(.vertical) {
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
                                Text(mode.titleKey)
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
                .clipShape(.capsule)

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
                        .fill(AppTheme.Colors.translucentSurfaceBackground)
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
                                
                                // Subtle border for all circles to make them visible
                                Circle()
                                    .stroke(AppTheme.Colors.detailDivider, lineWidth: 0.5)
                                    .frame(width: 24, height: 24)

                                if viewModel.selectedTheme == theme {
                                    Circle()
                                        .stroke(AppTheme.Colors.accentBlue, lineWidth: 2.2)
                                        .frame(width: 24, height: 24)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(theme == .charcoal || theme == .black ? .white : AppTheme.Colors.accentBlue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("reader.theme.\(theme.rawValue)")
                        .accessibilityValue(
                            viewModel.selectedTheme == theme
                                ? AppLocalization.string("selected")
                                : AppLocalization.string("unselected")
                        )
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
                                    .fill(
                                        viewModel.selectedFontName == fontName
                                            ? AppTheme.Colors.surfaceBackground
                                            : .clear
                                    )
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
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var chapterListOverlay: some View {
        ReaderChapterListOverlay(
            chapters: viewModel.chapterList,
            currentChapterIndex: viewModel.currentChapterIndex,
            onBack: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.dismissChapterList()
                }
            },
            onReload: {
                viewModel.didTapPanelAction(AppLocalization.string("Tải lại nội dung"))
            },
            onSelectChapter: { chapterIndex in
                viewModel.jumpToChapter(chapterIndex)
            }
        )
        .accessibilityIdentifier("screen.reader.chapter_list")
    }

    private func quickAction(
        icon: String,
        title: String,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(LocalizedStringKey(title))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private func panelActionRow(icon: String, title: String) -> some View {
        Button {
            viewModel.didTapPanelAction(AppLocalization.string(title))
        } label: {
            HStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.mutedIcon)
                    .frame(width: 30)

                Text(LocalizedStringKey(title))
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
                        .foregroundStyle(AppTheme.Colors.emphasizedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(AppTheme.Colors.emphasizedSurface))
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
            Text(LocalizedStringKey(text))
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

    private var panelBackdropTopInset: CGFloat {
        128
    }

    private var selectedDarkMode: ReaderDarkModeOption {
        ReaderDarkModeOption(rawValue: readerDarkModeRawValue) ?? .auto
    }

    private var selectedLightTheme: ReaderViewModel.ReaderThemeStyle {
        ReaderViewModel.ReaderThemeStyle(rawValue: readerLightThemeRawValue) ?? .light
    }

    private var selectedDarkTheme: ReaderViewModel.ReaderThemeStyle {
        ReaderViewModel.ReaderThemeStyle(rawValue: readerDarkThemeRawValue) ?? .charcoal
    }

    private var effectiveThemeFromSettings: ReaderViewModel.ReaderThemeStyle {
        selectedDarkMode.usesDarkTheme(systemScheme: colorScheme) ? selectedDarkTheme : selectedLightTheme
    }

    private func applyThemeFromSettings() {
        let theme = effectiveThemeFromSettings

        if viewModel.selectedTheme != theme {
            viewModel.setTheme(theme)
        }
    }

    private func persistThemeSelection(_ theme: ReaderViewModel.ReaderThemeStyle) {
        if selectedDarkMode.usesDarkTheme(systemScheme: colorScheme) {
            if readerDarkThemeRawValue != theme.rawValue {
                readerDarkThemeRawValue = theme.rawValue
            }
            return
        }

        if readerLightThemeRawValue != theme.rawValue {
            readerLightThemeRawValue = theme.rawValue
        }
    }

    private func reportCurrentProgress() {
        onProgressChange?(viewModel.currentChapterIndex, viewModel.totalChapters)
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
            return Color(red: 0, green: 0, blue: 0, opacity: 1.0)
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

private struct ReaderChapterListOverlay: View {
    let chapters: [BookChapter]
    let currentChapterIndex: Int
    let onBack: () -> Void
    let onReload: () -> Void
    let onSelectChapter: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.Colors.screenBackground.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("reader.chapter_list.back")

            Spacer()

            Button(action: onReload) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("reader.chapter_list.reload")
        }
        .overlay {
            Text(LocalizedStringKey("D.S Chương"))
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
        .safeAreaPadding(.top, 8)
        .padding(.bottom, 8)
    }

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(chapters) { chapter in
                        row(for: chapter)
                            .id(chapter.index)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                proxy.scrollTo(currentChapterIndex, anchor: .center)
            }
        }
    }

    private func row(for chapter: BookChapter) -> some View {
        let isCurrentChapter = chapter.index == currentChapterIndex

        return Button {
            onSelectChapter(chapter.index)
        } label: {
            HStack(alignment: .top, spacing: 16) {
                Text("\(chapter.index)")
                    .font(.system(size: 15, weight: isCurrentChapter ? .medium : .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(width: 34, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(chapter.title)
                        .font(.system(size: 16, weight: isCurrentChapter ? .medium : .regular))
                        .foregroundStyle(
                            isCurrentChapter
                                ? AppTheme.Colors.textPrimary
                                : AppTheme.Colors.textSecondary
                        )
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text("(\(chapter.timestampText))")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.9))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .background(
                isCurrentChapter
                    ? AppTheme.Colors.textPrimary.opacity(0.06)
                    : .clear
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("reader.chapter_list.row.\(chapter.index)")
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

#Preview("Reader Chapter List") {
    ReaderChapterListOverlay(
        chapters: (60...75).map { index in
            BookChapter(
                id: "rice-tea-chapter-\(index)",
                index: index,
                title: "Chương \(index): Tiểu Bạch tới giờ uống thuốc rồi",
                timestampText: "2023-01-04 21:12"
            )
        },
        currentChapterIndex: 66,
        onBack: {},
        onReload: {},
        onSelectChapter: { _ in }
    )
}
