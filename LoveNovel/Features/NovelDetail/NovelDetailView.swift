import SwiftUI

struct NovelDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NovelDetailViewModel
    @State private var readerDestination: ReaderDestination?
    private let scrollSpaceName = "novel_detail.scroll"

    init(book: Book) {
        _viewModel = StateObject(wrappedValue: NovelDetailViewModel(book: book))
    }

    init(viewModel: @autoclosure @escaping () -> NovelDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top

            ScrollView {
                VStack(spacing: 0) {
                    heroSection(topInset: topInset)
                    tabStrip
                    phaseContent
                }
                .padding(.bottom, bottomContentPadding)
            }
            .coordinateSpace(name: scrollSpaceName)
            .leftEdgeSwipeUpBackGesture {
                dismiss()
            }
            .background(AppTheme.Colors.screenBackground.ignoresSafeArea())
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .bottom) {
                bottomInset
            }
            .task {
                await viewModel.load()
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
            .navigationDestination(item: $readerDestination) { destination in
                ReaderView(
                    book: destination.book,
                    initialChapter: destination.chapter,
                    chapterCount: destination.chapterCount,
                    chapterList: destination.chapters,
                    onClose: {
                        readerDestination = nil
                    }
                )
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden(true)
            .accessibilityIdentifier("screen.novel_detail")
        }
    }

    private func heroSection(topInset: CGFloat) -> some View {
        GeometryReader { heroProxy in
            let minY = heroProxy.frame(in: .named(scrollSpaceName)).minY
            let pullDownOffset = max(minY, 0)
            let upwardScroll = max(-minY, 0)
            let collapseProgress = min(upwardScroll / 220, 1)
            let contentScale = max(0.88, 1 - (collapseProgress * 0.12))
            let contentYOffset = -(collapseProgress * 16)
            let coverWidth = max(88, min(108, heroProxy.size.width * 0.26))
            let coverHeight = coverWidth * 1.25
            let titleFontSize = max(19, min(25, heroProxy.size.width * 0.064))
            let authorFontSize = max(14, min(18, heroProxy.size.width * 0.044))
            let stretchScale = 1 + min(pullDownOffset / 420, 0.1)

            ZStack(alignment: .topLeading) {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: viewModel.book.accentHex).opacity(0.92),
                            Color.black.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 190, height: 190)
                        .offset(x: -90, y: -70)
                        .blur(radius: 22)

                    Circle()
                        .fill(Color(hex: viewModel.book.accentHex).opacity(0.45))
                        .frame(width: 260, height: 260)
                        .offset(x: 140, y: -32)
                        .blur(radius: 30)

                    Circle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 190, height: 190)
                        .offset(x: 174, y: 110)
                        .blur(radius: 34)
                }
                .scaleEffect(stretchScale, anchor: .center)
                .overlay(AppTheme.Colors.heroOverlay.opacity(0.8))
                .blur(radius: collapseProgress * 5)
                .clipped()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("novel_detail.back")

                        Spacer()
                    }

                    HStack(alignment: .top, spacing: 10) {
                        HeroCoverCard(
                            book: viewModel.book,
                            width: coverWidth,
                            height: coverHeight
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(heroPrimaryGenre)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(AppTheme.Colors.accentBlue.opacity(0.9)))

                            Text(viewModel.book.title)
                                .font(.system(size: titleFontSize, weight: .semibold))
                                .minimumScaleFactor(0.55)
                                .lineLimit(2)
                                .foregroundStyle(.white)

                            Text(viewModel.book.author)
                                .font(.system(size: authorFontSize, weight: .regular))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .foregroundStyle(.white.opacity(0.9))

                            HStack(spacing: 5) {
                                ForEach(0..<5, id: \.self) { index in
                                    Image(systemName: index < Int(viewModel.book.rating.rounded()) ? "star.fill" : "star")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(AppTheme.Colors.star)
                                }

                                Text(String(format: "%.1f", viewModel.book.rating))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.92))

                                Text(heroReviewCountText)
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.86))
                                    .lineLimit(1)
                            }
                        }

                        Spacer(minLength: 0)
                    }

                    HStack(spacing: 8) {
                        Button {
                            openReaderFromCurrentContext()
                        } label: {
                            Text("Đọc truyện")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(AppTheme.Colors.accentBlue))
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.didTapAddToLibrary()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppTheme.Colors.accentBlue)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(.white))

                                Text("Thêm vào\nTủ Truyện")
                                    .font(.system(size: 10, weight: .regular))
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(.white.opacity(0.92))
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)
                    }
                }
                .padding(.horizontal, AppTheme.Layout.horizontalInset)
                .padding(.top, topInset + 6)
                .padding(.bottom, 8)
                .scaleEffect(contentScale, anchor: .topLeading)
                .offset(y: contentYOffset)
            }
            .frame(height: AppTheme.Layout.detailHeroHeight + topInset + pullDownOffset)
            .clipped()
            .offset(y: -pullDownOffset)
        }
        .frame(height: AppTheme.Layout.detailHeroHeight + topInset)
    }

    private var tabStrip: some View {
        HStack(spacing: 0) {
            ForEach(NovelDetailViewModel.Tab.allCases) { tab in
                Button {
                    viewModel.setTab(tab)
                } label: {
                    VStack(spacing: 10) {
                        Text(tab.titleKey)
                            .font(.system(size: 16, weight: viewModel.selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(viewModel.selectedTab == tab ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)

                        Capsule()
                            .fill(AppTheme.Colors.textPrimary)
                            .frame(width: 92, height: 3.5)
                            .opacity(viewModel.selectedTab == tab ? 1 : 0)
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(tabIdentifier(for: tab))
            }
        }
        .frame(height: AppTheme.Layout.detailTabHeight)
        .background(.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.Colors.detailDivider)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .idle, .loading:
            VStack(spacing: 12) {
                ProgressView()
                    .tint(AppTheme.Colors.accentBlue)
                Text("Loading story details...")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)

        case .failed:
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.errorMessage ?? "Could not load story details.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Button("Try Again") {
                    Task {
                        await viewModel.load(force: true)
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.top, 40)

        case .loaded:
            if let detail = viewModel.detail {
                loadedContent(detail)
            }
        }
    }

    @ViewBuilder
    private func loadedContent(_ detail: BookDetail) -> some View {
        switch viewModel.selectedTab {
        case .info:
            infoTab(detail)
        case .review:
            reviewTab(detail)
        case .comments:
            commentsTab(detail)
        case .content:
            contentTab(detail)
        }
    }

    private func infoTab(_ detail: BookDetail) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.detailSectionSpacing) {
            HStack(spacing: 0) {
                statColumn(
                    value: "\(detail.chapterCount)",
                    subtitle: AppLocalization.format(
                        "novel_detail.stats.chapters_status",
                        detail.status == .ongoing
                            ? AppLocalization.string("Ongoing")
                            : AppLocalization.string("Completed")
                    )
                )

                statColumn(value: detail.viewsLabel, subtitle: AppLocalization.string("Views"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)

            Text(detail.longDescription)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineSpacing(4)
                .padding(.horizontal, AppTheme.Layout.horizontalInset)

            chipSection(titleKey: "Thể loại", values: detail.genres)
            chipSection(titleKey: "Nhãn", values: detail.tags)

            if !detail.sameAuthorBooks.isEmpty {
                relatedSectionHeader(title: AppLocalization.string("Cùng tác giả"))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(detail.sameAuthorBooks) { relatedBook in
                            AuthorRelatedBookCard(book: relatedBook)
                        }
                    }
                    .padding(.horizontal, AppTheme.Layout.horizontalInset)
                }
            }

            if !detail.sameUploaderBooks.isEmpty {
                relatedSectionHeader(title: AppLocalization.format("novel_detail.related.same_uploader", detail.uploaderName))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(detail.sameUploaderBooks) { relatedBook in
                            UploaderRelatedBookCard(book: relatedBook)
                        }
                    }
                    .padding(.horizontal, AppTheme.Layout.horizontalInset)
                }
            }

            Button {
                viewModel.alertMessage = AppLocalization.string("Report flow is coming in v2.")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 15, weight: .regular))
                    Text("Báo lỗi")
                        .font(.system(size: 15, weight: .regular))
                }
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
    }

    private func reviewTab(_ detail: BookDetail) -> some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 16) {
                if viewModel.displayedReviews.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 54, weight: .regular))
                            .foregroundStyle(AppTheme.Colors.mutedIcon)
                        Text("No Reviews")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .accessibilityIdentifier("novel_detail.empty.reviews")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 105)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.displayedReviews) { review in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(review.author)
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    Text(String(format: "%.1f ★", review.rating))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                }

                                Text(review.body)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(AppTheme.Colors.textPrimary)

                                Text(review.createdAtText)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                        }
                    }
                    .padding(.horizontal, AppTheme.Layout.horizontalInset)
                    .padding(.top, 20)
                }
            }

            Button {
                viewModel.didTapWriteReview()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(AppTheme.Colors.accentBlue))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.trailing, AppTheme.Layout.horizontalInset)
            .padding(.bottom, 96)
        }
    }

    private func commentsTab(_ detail: BookDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 0) {
                ForEach(NovelDetailViewModel.CommentSort.allCases) { option in
                    Button {
                        viewModel.setCommentSort(option)
                    } label: {
                        Text(option.titleKey)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(viewModel.commentSort == option ? .white : AppTheme.Colors.accentBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(viewModel.commentSort == option ? AppTheme.Colors.accentBlue : .clear)
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay(
                Capsule()
                    .stroke(AppTheme.Colors.pillBorder, lineWidth: 1.5)
            )
            .clipShape(Capsule())
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.top, 20)

            if viewModel.displayedComments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 54, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.mutedIcon)
                    Text("No Comments")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .accessibilityIdentifier("novel_detail.empty.comments")
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 96)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(viewModel.displayedComments) { comment in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack {
                                Text(comment.author)
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Text("♥︎ \(comment.likes)")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }

                            Text(comment.body)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(AppTheme.Colors.textPrimary)

                            Text(comment.createdAtText)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                    }
                }
                .padding(.horizontal, AppTheme.Layout.horizontalInset)
            }
        }
    }

    private func contentTab(_ detail: BookDetail) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(AppLocalization.format("novel_detail.chapters.count", detail.chapterCount))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Spacer()

                Button {
                    viewModel.toggleChapterOrder()
                } label: {
                    Image(systemName: viewModel.chapterOrder == .newest ? "line.3.horizontal.decrease" : "line.3.horizontal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("novel_detail.chapter_order")
            }
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.top, 12)

            VStack(alignment: .leading, spacing: 18) {
                ForEach(viewModel.displayedChapters) { chapter in
                    Button {
                        openReader(chapter: chapter, chapterCount: detail.chapterCount)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(chapter.index)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .frame(width: 28, alignment: .leading)

                            Text("\(chapter.title) (\(chapter.timestampText))")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("novel_detail.chapter_row.\(chapter.index)")
                }
            }
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private var bottomInset: some View {
        if viewModel.phase == .loaded {
            Group {
                if viewModel.selectedTab == .comments {
                    commentComposerBar
                } else {
                    readActionBar
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, AppTheme.Layout.detailBottomInset)
        }
    }

    private var readActionBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.book.title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                if viewModel.selectedTab == .info {
                    Text(viewModel.book.author)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                openReaderFromCurrentContext()
            } label: {
                Text("Đọc")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.black))
            }
            .buttonStyle(.plain)

            Button {
                viewModel.didTapAddToLibrary()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(AppTheme.Colors.accentBlue))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.detailActionBarCornerRadius)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
    }

    private func openReaderFromCurrentContext() {
        guard
            let detail = viewModel.detail,
            let chapter = viewModel.displayedChapters.first
        else {
            viewModel.alertMessage = AppLocalization.string("Chapter list is still loading.")
            return
        }

        openReader(chapter: chapter, chapterCount: detail.chapterCount)
    }

    private func openReader(chapter: BookChapter, chapterCount: Int) {
        readerDestination = ReaderDestination(
            book: viewModel.book,
            chapter: chapter,
            chapterCount: chapterCount,
            chapters: viewModel.displayedChapters.sorted { lhs, rhs in
                lhs.index < rhs.index
            }
        )
    }

    private var commentComposerBar: some View {
        HStack(spacing: 14) {
            Image(systemName: "text.bubble")
                .font(.system(size: 21, weight: .regular))
                .foregroundStyle(AppTheme.Colors.mutedIcon)

            TextField("Add a comment", text: $viewModel.draftComment)
                .font(.system(size: 15, weight: .regular))
                .keyboardType(.default)

            Button {
                viewModel.didTapSendComment()
            } label: {
                Image(systemName: "paperplane")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.mutedIcon)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.Colors.pillBorder, lineWidth: 1.2)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.8))
                )
        )
    }

    private var heroPrimaryGenre: String {
        guard let firstGenre = viewModel.detail?.genres.first, !firstGenre.isEmpty else {
            return AppLocalization.string("Tiên Hiệp")
        }

        return firstGenre
    }

    private var heroReviewCountText: String {
        let reviewCount = viewModel.detail?.reviews.count ?? 0

        if reviewCount == 0 {
            return AppLocalization.string("(chưa có đánh giá)")
        }

        return AppLocalization.format("novel_detail.reviews.count", reviewCount)
    }

    private func tabIdentifier(for tab: NovelDetailViewModel.Tab) -> String {
        switch tab {
        case .info:
            return "novel_detail.tab.info"
        case .review:
            return "novel_detail.tab.review"
        case .comments:
            return "novel_detail.tab.comments"
        case .content:
            return "novel_detail.tab.content"
        }
    }

    private func statColumn(value: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text(subtitle)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func chipSection(titleKey: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(values, id: \.self) { value in
                        Text(value.uppercased())
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.accentBlue)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.85))
                            )
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
    }

    private func relatedSectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
    }

    private var bottomContentPadding: CGFloat {
        guard viewModel.phase == .loaded else {
            return 16
        }

        if viewModel.selectedTab == .comments {
            return 92
        }

        return 112
    }
}

private struct ReaderDestination: Identifiable, Hashable {
    let book: Book
    let chapter: BookChapter
    let chapterCount: Int
    let chapters: [BookChapter]

    var id: String {
        "\(book.id)-\(chapter.id)-\(chapterCount)"
    }

    static func == (lhs: ReaderDestination, rhs: ReaderDestination) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private struct HeroCoverCard: View {
    let book: Book
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: book.accentHex),
                        Color(hex: book.accentHex).opacity(0.4),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.26), radius: 14, y: 8)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text("A novel about the digital underground")
                        .font(.system(size: 6.5, weight: .regular))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)

                    Text(book.author)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(8)
            }
    }
}

private struct AuthorRelatedBookCard: View {
    let book: RelatedBook

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: book.accentHex),
                            Color(hex: book.accentHex).opacity(0.45),
                            Color.black.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 98, height: 132)
                .overlay(alignment: .bottomLeading) {
                    Text(book.title)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .padding(7)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(book.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(book.summary)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(2)

                Spacer()

                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < Int(book.rating.rounded()) ? "star.fill" : "star")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.star)
                    }
                    Text(String(format: "%.1f", book.rating))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .padding(.leading, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(9)
        .frame(width: 290, height: 148)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
    }
}

private struct UploaderRelatedBookCard: View {
    let book: RelatedBook

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: book.accentHex),
                            Color(hex: book.accentHex).opacity(0.45),
                            Color.black.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 88, height: 120)
                .overlay(alignment: .bottomLeading) {
                    Text(book.title)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .padding(6)
                }

            Text(book.title)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(2)

            Text(book.author)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 88, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        NovelDetailView(
            book: Book(
                id: "rice-tea",
                title: "Rice Tea",
                author: "Creative Commons",
                summary: "Preview summary",
                rating: 4.6,
                accentHex: "1B3B72"
            )
        )
    }
}
