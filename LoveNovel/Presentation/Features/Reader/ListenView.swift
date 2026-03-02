import SwiftUI
import LoveNovelCore
import LoveNovelDomain

struct ListenView: View {
    @ObservedObject var viewModel: ReaderViewModel
    @State private var isChapterListVisible: Bool = false
    @State private var isSettingsVisible: Bool = false
    @FocusState private var isSleepTimerFieldFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.Colors.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                toolbarRow
                chapterTitle
                coverArt
                transportControls
                progressSection
                Spacer()
                sleepTimerButton
            }
            .padding(.bottom, 24)

            if isChapterListVisible {
                chapterListOverlay
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(5)
            }

            if isSettingsVisible {
                listenSettingsOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(6)
            }

            if viewModel.isSleepTimerDialogVisible {
                sleepTimerDialogOverlay
                    .transition(.opacity)
                    .zIndex(7)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isChapterListVisible)
        .animation(.easeInOut(duration: 0.2), value: isSettingsVisible)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSleepTimerDialogVisible)
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
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.dismissListenPage()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("listen.back")

            Spacer()

            Text(viewModel.book.title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Toolbar Row

    private var toolbarRow: some View {
        HStack(spacing: 0) {
            toolbarButton(icon: "list.bullet", titleKey: "reader.listen.toolbar.chapters", identifier: "listen.toolbar.chapters") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isChapterListVisible = true
                }
            }
            toolbarButton(icon: "gearshape", titleKey: "reader.listen.toolbar.settings", identifier: "listen.toolbar.settings") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSettingsVisible = true
                    viewModel.showListenSettings()
                }
            }
            toolbarButton(icon: "questionmark.circle", titleKey: "reader.listen.toolbar.guide", identifier: "listen.toolbar.guide") {
                viewModel.didTapPanelAction(AppLocalization.string("reader.listen.toolbar.guide"))
            }
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
    }

    private func toolbarButton(
        icon: String,
        titleKey: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Text(LocalizedStringKey(titleKey))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    // MARK: - Chapter Title

    private var chapterTitle: some View {
        Text(viewModel.currentChapter.title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.top, 20)
    }

    // MARK: - Cover Art

    private var coverArt: some View {
        NovelCoverCard(
            book: viewModel.book,
            width: 220,
            height: 300,
            cornerRadius: 16,
            variant: .hero,
            shadowRadius: 12,
            shadowYOffset: 6
        )
        .padding(.top, 24)
        .padding(.bottom, 28)
    }

    // MARK: - Transport Controls

    private var transportControls: some View {
        HStack(spacing: 44) {
            Button {
                viewModel.moveChapter(by: -1)
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("listen.previous")

            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("listen.play_pause")

            Button {
                viewModel.moveChapter(by: 1)
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("listen.next")
        }
        .padding(.bottom, 20)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text(viewModel.chapterProgressPercent)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Spacer()

                Text(viewModel.chapterPositionText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Slider(
                value: Binding(
                    get: { Double(viewModel.currentChapterIndex) },
                    set: { viewModel.updateChapterSlider(to: $0) }
                ),
                in: 1...Double(viewModel.totalChapters),
                step: 1
            )
            .tint(AppTheme.Colors.accentBlue)

            Text(viewModel.currentChapter.title)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
    }

    // MARK: - Sleep Timer Button

    private var sleepTimerButton: some View {
        Button {
            viewModel.showSleepTimerDialog()
            isSleepTimerFieldFocused = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(sleepTimerLabel)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("listen.sleep_timer")
    }

    // MARK: - Overlays

    private var chapterListOverlay: some View {
        ListenChapterListOverlay(
            chapters: viewModel.chapterList,
            currentChapterIndex: viewModel.currentChapterIndex,
            onBack: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isChapterListVisible = false
                }
            },
            onSelectChapter: { chapterIndex in
                viewModel.jumpToChapter(chapterIndex)
                withAnimation(.easeInOut(duration: 0.2)) {
                    isChapterListVisible = false
                }
            }
        )
        .accessibilityIdentifier("screen.listen.chapter_list")
    }

    private var listenSettingsOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.36)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .allowsHitTesting(viewModel.isListenSettingsBackdropEnabled)
                .onTapGesture {
                    dismissSettings()
                }

            VStack(alignment: .leading, spacing: 0) {
                settingsHeader
                    .padding(.bottom, 20)

                listenSourceSection
                    .padding(.bottom, 18)

                listenSpeedSection
                    .padding(.bottom, 18)

                settingsSleepTimerRow
            }
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.top, 20)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 22,
                    topTrailingRadius: 22
                )
                .fill(AppTheme.Colors.screenBackground)
                .ignoresSafeArea(edges: .bottom)
            )
            .accessibilityIdentifier("listen.settings")
        }
    }

    private var settingsHeader: some View {
        HStack {
            Text("reader.listen.settings.title")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            Button {
                dismissSettings()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("listen.settings.close")
        }
    }

    private var listenSourceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("reader.listen.settings.source")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleListenSourceList()
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedListenSource.titleKey)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .rotationEffect(.degrees(viewModel.isListenSourceListVisible ? 180 : 0))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("listen.source.trigger")

                if viewModel.isListenSourceListVisible {
                    Divider()
                        .padding(.leading, 14)

                    ForEach(Array(ReaderViewModel.ListenSource.allCases.enumerated()), id: \.element) { offset, source in
                        let isSelected = viewModel.selectedListenSource == source

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.setListenSource(source)
                            }
                        } label: {
                            HStack {
                                Text(source.titleKey)
                                    .font(.system(size: 16, weight: isSelected ? .medium : .regular))
                                    .foregroundStyle(AppTheme.Colors.textPrimary)

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppTheme.Colors.accentBlue)
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(
                                isSelected
                                    ? AppTheme.Colors.accentBlue.opacity(0.08)
                                    : .clear
                            )
                        }
                        .buttonStyle(.plain)

                        if offset < ReaderViewModel.ListenSource.allCases.count - 1 {
                            Divider()
                                .padding(.leading, 14)
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.Colors.translucentSurfaceBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var listenSpeedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("reader.listen.settings.speed")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                Text("\(formattedListenSpeed)x")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accentBlue)
                    .monospacedDigit()
            }

            Slider(
                value: Binding(
                    get: { viewModel.listenSpeed },
                    set: { viewModel.setListenSpeed($0) }
                ),
                in: 0.5...2.0,
                step: 0.05
            )
            .tint(AppTheme.Colors.accentBlue)

            HStack {
                Text("0.5x")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Spacer()

                Text("1.0x")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Spacer()

                Text("2.0x")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, 2)
        }
    }

    private var settingsSleepTimerRow: some View {
        Button {
            viewModel.showSleepTimerDialog()
            isSleepTimerFieldFocused = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.accentBlue)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.Colors.accentBlue.opacity(0.12))
                    )

                Text(sleepTimerLabel)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.Colors.translucentSurfaceBackground)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("listen.settings.sleep_timer")
    }

    private func dismissSettings() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSettingsVisible = false
            viewModel.dismissListenSettings()
        }
    }

    private var sleepTimerDialogOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.dismissSleepTimerDialog()
                    isSleepTimerFieldFocused = false
                }

            VStack(alignment: .leading, spacing: 18) {
                Text("reader.listen.sleep_dialog.title")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                TextField("", text: $viewModel.sleepTimerInputMinutes)
                    .focused($isSleepTimerFieldFocused)
                    .keyboardType(.numberPad)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .padding(.bottom, 8)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(AppTheme.Colors.detailDivider)
                            .frame(height: 1)
                    }
                    .accessibilityIdentifier("listen.sleep_input")

                HStack {
                    Spacer()

                    Button("reader.listen.sleep_dialog.cancel") {
                        viewModel.dismissSleepTimerDialog()
                        isSleepTimerFieldFocused = false
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.accentBlue)
                    .accessibilityIdentifier("listen.sleep_cancel")

                    Button("reader.listen.sleep_dialog.confirm") {
                        viewModel.confirmSleepTimer()
                        isSleepTimerFieldFocused = false
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .accessibilityIdentifier("listen.sleep_confirm")
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: 600)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.Colors.screenBackground)
            )
            .padding(.horizontal, 28)
            .accessibilityIdentifier("listen.sleep_dialog")
        }
    }

    // MARK: - Helpers

    private var formattedListenSpeed: String {
        viewModel.listenSpeed.formatted(.number.precision(.fractionLength(0...2)))
    }

    private var sleepTimerLabel: String {
        if let configuredMinutes = viewModel.sleepTimerMinutes {
            return AppLocalization.format("reader.listen.settings.sleep_timer_with_value", configuredMinutes)
        }

        return AppLocalization.string("reader.listen.settings.sleep_timer")
    }
}

// MARK: - Chapter List Overlay

private struct ListenChapterListOverlay: View {
    let chapters: [BookChapter]
    let currentChapterIndex: Int
    let onBack: () -> Void
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
            .accessibilityIdentifier("listen.chapter_list.back")

            Spacer()
        }
        .overlay {
            Text("reader.listen.chapter_list.title")
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
        .accessibilityIdentifier("listen.chapter_list.row.\(chapter.index)")
    }
}

// MARK: - Previews

#Preview {
    ListenView(
        viewModel: PreviewFeatureFactory.live.makeReaderViewModel(
            book: Book(
                id: "rice-tea",
                title: "Rice Tea",
                author: "Julien McArdle",
                summary: "Bach Muc doi dien mot thanh pho phu day tin hieu nhieu.",
                rating: 4.6,
                accentHex: "1B3B72"
            ),
            initialChapter: BookChapter(
                id: "rice-tea-chapter-3",
                index: 3,
                title: "Chuong 3: Tin hieu tu vung cam",
                timestampText: "2020-04-02 00:58"
            ),
            chapterCount: 55,
            chapters: [],
            shouldShowTutorial: false
        )
    )
}
