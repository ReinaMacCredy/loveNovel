import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel: ExploreViewModel
    @State private var selectedBook: Book?
    @State private var isStoryModeSheetPresented: Bool = false
    @State private var isShowingSearch: Bool = false
    @State private var isShowingAllStories: Bool = false
    @State private var selectedBannerID: Book.ID?
    @State private var isBannerDragging: Bool = false
    private let bannerAutoScrollTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    init(viewModel: @autoclosure @escaping () -> ExploreViewModel = ExploreViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    stateContent
                }
                .padding(.horizontal, AppTheme.Layout.horizontalInset)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .background(AppTheme.Colors.screenBackground.ignoresSafeArea())
            .task {
                await viewModel.load()
            }
            .sheet(isPresented: $isStoryModeSheetPresented) {
                ExploreStoryModeSheet(
                    isPresented: $isStoryModeSheetPresented,
                    selectedMode: storyModeBinding
                )
                .presentationDetents([.height(330)])
                .presentationDragIndicator(.hidden)
            }
            .alert(
                "Coming Soon",
                isPresented: Binding(
                    get: { viewModel.placeholderMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.dismissPlaceholder()
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.dismissPlaceholder()
                }
            } message: {
                Text(viewModel.placeholderMessage ?? "")
            }
            .navigationDestination(item: $selectedBook) { book in
                NovelDetailView(book: book)
            }
            .navigationDestination(isPresented: $isShowingSearch) {
                ExploreSearchView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $isShowingAllStories) {
                ExploreAllStoriesView(viewModel: viewModel)
            }
            .toolbar((isShowingSearch || isShowingAllStories) ? .hidden : .automatic, for: .tabBar)
            .animation(.smooth, value: isShowingSearch)
            .animation(.smooth, value: isShowingAllStories)
            .accessibilityIdentifier("screen.explore")
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: -8) {
                iconBubble(symbol: "heart.fill", background: Color(red: 0.17, green: 0.28, blue: 0.39))
                iconBubble(symbol: "heart.circle.fill", background: Color(red: 0.40, green: 0.75, blue: 0.92))
            }

            Button {
                isStoryModeSheetPresented = true
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.selectedStoryMode.headerTitle)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("explore.header.story_mode")

            Spacer()

            HStack(spacing: 18) {
                Button {
                    isShowingSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("explore.header.search")

                Button {
                    isShowingAllStories = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("explore.header.filter")
            }
        }
    }

    private var storyModeBinding: Binding<ExploreViewModel.StoryMode> {
        Binding(
            get: { viewModel.selectedStoryMode },
            set: { storyMode in
                viewModel.setStoryMode(storyMode)
            }
        )
    }

    private func iconBubble(symbol: String, background: Color) -> some View {
        ZStack {
            Circle()
                .fill(background)
                .frame(width: 42, height: 42)

            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.phase {
        case .idle, .loading:
            VStack(alignment: .center, spacing: 12) {
                ProgressView()
                    .tint(AppTheme.Colors.accentBlue)
                Text("Loading stories...")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 100)

        case .failed:
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.errorMessage ?? "Could not load stories.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Button("Try Again") {
                    Task {
                        await viewModel.load(force: true)
                    }
                }
                .font(.system(size: 17, weight: .semibold))
            }
            .padding(.top, 60)

        case .loaded:
            if let feed = viewModel.feed {
                loadedContent(feed)
            }
        }
    }

    private func loadedContent(_ feed: HomeFeed) -> some View {
        let allBooks = uniqueBooks(in: feed)
        let heroBooks = heroBooks(from: feed)
        let latestBooks = Array(feed.latest.prefix(8))
        let recommendedBooks = Array(feed.recommended.prefix(6))
        let realtimeBooks = realtimeBooks(from: allBooks)
        let newlyPostedBooks = Array(feed.moreLikeThis.prefix(6))
        let completedBooks = completedBooks(from: allBooks)

        return VStack(alignment: .leading, spacing: 22) {
            if !heroBooks.isEmpty {
                bannerSection(books: heroBooks)
            }

            if !latestBooks.isEmpty {
                SectionHeader(title: "Mới nhất") {
                    viewModel.showPlaceholder(message: AppLocalization.string("Latest list actions are coming in v2."))
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(latestBooks) { book in
                            Button {
                                selectedBook = book
                            } label: {
                                ExploreCompactCover(book: book)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("book.cover.\(book.id)")
                        }
                    }
                }
                .scrollClipDisabled()
            }

            featuredSection(book: feed.featured)

            if !recommendedBooks.isEmpty {
                SectionHeader(title: "Đề cử") {
                    viewModel.showPlaceholder(message: AppLocalization.string("Recommended actions are coming in v2."))
                }

                recommendedSection(books: recommendedBooks)
            }

            if !realtimeBooks.isEmpty {
                SectionHeader(title: "Thời gian thực") {
                    viewModel.showPlaceholder(message: AppLocalization.string("More-like-this actions are coming in v2."))
                }

                realtimeSection(books: realtimeBooks, allBooks: allBooks)
            }

            if !newlyPostedBooks.isEmpty {
                newlyPostedSection(books: newlyPostedBooks)
                    .padding(.horizontal, -AppTheme.Layout.horizontalInset)
            }

            if !completedBooks.isEmpty {
                SectionHeader(title: "Mới hoàn thành") {
                    viewModel.showPlaceholder(message: AppLocalization.string("More-like-this actions are coming in v2."))
                }

                completedSection(books: completedBooks, allBooks: allBooks)
            }
        }
    }

    private func bannerSection(books: [Book]) -> some View {
        GeometryReader { proxy in
            let cardWidth = proxy.size.width

            VStack(spacing: 8) {
                TabView(selection: $selectedBannerID) {
                    ForEach(books) { book in
                        Button {
                            selectedBook = book
                        } label: {
                            ExploreBannerCard(book: book)
                                .frame(width: cardWidth, height: 196)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("book.cover.\(book.id)")
                        .tag(Optional(book.id))
                    }
                }
                .frame(height: 196)
                .clipShape(.rect(cornerRadius: 14, style: .continuous))
                .tabViewStyle(.page(indexDisplayMode: .never))
                .simultaneousGesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { _ in
                            if !isBannerDragging {
                                isBannerDragging = true
                            }
                        }
                        .onEnded { _ in
                            isBannerDragging = false
                        }
                )
                .onAppear {
                    if selectedBannerID == nil {
                        selectedBannerID = books.first?.id
                    }
                }
                .onReceive(bannerAutoScrollTimer) { _ in
                    guard books.count > 1,
                          !isBannerDragging,
                          let currentID = selectedBannerID,
                          let currentIndex = books.firstIndex(where: { $0.id == currentID })
                    else { return }
                    let nextIndex = (currentIndex + 1) % books.count
                    withAnimation(.easeInOut(duration: 0.35)) {
                        selectedBannerID = books[nextIndex].id
                    }
                }

                HStack(spacing: 8) {
                    ForEach(books) { book in
                        Capsule()
                            .fill(book.id == selectedBannerID ? Color.black.opacity(0.42) : Color.black.opacity(0.18))
                            .frame(width: book.id == selectedBannerID ? 18 : 10, height: 4)
                    }
                }
            }
        }
        .frame(height: 208)
    }

    private func featuredSection(book: Book) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(genreText(for: book))
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Text(book.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(2)

                Text(tagsSummary(for: book))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(2)

                StarRatingRow(rating: book.rating, starSize: 14)

                HStack(spacing: 12) {
                    Button {
                        viewModel.didTapRead(book)
                    } label: {
                        Text(AppLocalization.string("Đọc"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(minWidth: 84)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.black))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.didTapAdd(book)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppTheme.Colors.accentBlue))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                selectedBook = book
            } label: {
                ExplorePosterCard(book: book, width: 134, height: 194)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("book.cover.\(book.id)")
        }
    }

    private func recommendedSection(books: [Book]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(books) { book in
                Button {
                    selectedBook = book
                } label: {
                    ExploreGridCard(book: book, subtitle: genreText(for: book))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("book.cover.\(book.id)")
            }
        }
    }

    private func realtimeSection(books: [Book], allBooks: [Book]) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                let trailingBook = allBooks.isEmpty ? book : allBooks[(index + 1) % allBooks.count]

                HStack(spacing: 10) {
                    Button {
                        selectedBook = book
                    } label: {
                        ExplorePosterCard(book: book, width: 62, height: 82)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("book.cover.\(book.id)")

                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .lineLimit(2)

                        Text(genreText(for: book))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineLimit(1)

                        Text("\(viewsText(for: book)) \(AppLocalization.string("Đang đọc"))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.7))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    Button {
                        selectedBook = trailingBook
                    } label: {
                        ExplorePosterCard(book: trailingBook, width: 62, height: 82)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("book.cover.\(trailingBook.id)")
                }
            }
        }
    }

    private func newlyPostedSection(books: [Book]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStringKey("Mới đăng"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    viewModel.showPlaceholder(message: AppLocalization.string("More-like-this actions are coming in v2."))
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(books) { book in
                        Button {
                            selectedBook = book
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                ExplorePosterCard(book: book, width: 108, height: 138)
                                Text(book.title)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.92))
                                    .lineLimit(2)
                            }
                            .frame(width: 108, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("book.cover.\(book.id)")
                    }
                }
            }
            .scrollClipDisabled()
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
        .padding(.vertical, 14)
        .background(Color.black)
    }

    private func completedSection(books: [Book], allBooks: [Book]) -> some View {
        VStack(spacing: 14) {
            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                let trailingBook = allBooks.isEmpty
                    ? book
                    : Array(allBooks.reversed())[index % allBooks.count]

                HStack(alignment: .top, spacing: 10) {
                    Button {
                        selectedBook = book
                    } label: {
                        ExplorePosterCard(book: book, width: 62, height: 82)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("book.cover.\(book.id)")

                    VStack(alignment: .leading, spacing: 5) {
                        Text(book.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .lineLimit(2)

                        Text(genreText(for: book))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineLimit(1)

                        StarRatingRow(rating: book.rating, starSize: 12)
                    }

                    Spacer(minLength: 4)

                    Button {
                        selectedBook = trailingBook
                    } label: {
                        ExplorePosterCard(book: trailingBook, width: 62, height: 82)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("book.cover.\(trailingBook.id)")
                }
            }
        }
    }

    private func uniqueBooks(in feed: HomeFeed) -> [Book] {
        var seenBookIDs = Set<String>()
        let orderedBooks = feed.latest + [feed.featured] + feed.recommended + feed.moreLikeThis

        return orderedBooks.filter { book in
            seenBookIDs.insert(book.id).inserted
        }
    }

    private func heroBooks(from feed: HomeFeed) -> [Book] {
        let ordered = [feed.featured] + uniqueBooks(in: feed)
        var seen = Set<String>()

        return ordered.filter { book in
            seen.insert(book.id).inserted
        }
        .prefix(4)
        .map { $0 }
    }

    private func realtimeBooks(from allBooks: [Book]) -> [Book] {
        let ongoing = allBooks.filter { book in
            guard let detail = viewModel.detailsByBookID[book.id] else {
                return false
            }
            return detail.status == .ongoing
        }

        return Array(ongoing.prefix(3))
    }

    private func completedBooks(from allBooks: [Book]) -> [Book] {
        let completed = allBooks.filter { book in
            guard let detail = viewModel.detailsByBookID[book.id] else {
                return false
            }
            return detail.status == .completed
        }

        return Array(completed.prefix(3))
    }

    private func genreText(for book: Book) -> String {
        guard let genre = viewModel.detailsByBookID[book.id]?.genres.first else {
            return book.author
        }

        return genre
    }

    private func tagsSummary(for book: Book) -> String {
        guard let tags = viewModel.detailsByBookID[book.id]?.tags, !tags.isEmpty else {
            return book.summary
        }

        return tags.map { "[ \($0) ]" }.joined(separator: " + ")
    }

    private func viewsText(for book: Book) -> String {
        viewModel.detailsByBookID[book.id]?.viewsLabel ?? "0"
    }
}

private struct ExploreBannerCard: View {
    let book: Book

    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    colors: [Color(hex: book.accentHex), Color.black.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottomLeading) {
                Text(book.title)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
    }
}

private struct ExploreCompactCover: View {
    let book: Book

    var body: some View {
        ExplorePosterCard(book: book, width: 64, height: 84)
    }
}

private struct ExplorePosterCard: View {
    let book: Book
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(
                LinearGradient(
                    colors: [Color(hex: book.accentHex), Color.black.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: width, height: height)
            .overlay(alignment: .bottomLeading) {
                Text(book.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(8)
            }
            .shadow(color: Color.black.opacity(0.14), radius: 3, y: 2)
    }
}

private struct ExploreGridCard: View {
    let book: Book
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ExplorePosterCard(book: book, width: 108, height: 138)

            Text(book.title)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(2)

            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StarRatingRow: View {
    let rating: Double
    let starSize: CGFloat

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: starSymbol(for: index))
                    .font(.system(size: starSize, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.star)
            }

            Text(String(format: "%.1f", rating))
                .font(.system(size: max(starSize + 1, 13), weight: .regular))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(.leading, 6)
        }
    }

    private func starSymbol(for index: Int) -> String {
        let threshold = Double(index) + 1
        if rating >= threshold {
            return "star.fill"
        }

        if rating + 0.5 >= threshold {
            return "star.leadinghalf.filled"
        }

        return "star"
    }
}

#Preview {
    ExploreView()
}
