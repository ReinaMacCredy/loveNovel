import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel: ExploreViewModel
    @State private var selectedBook: Book?
    @State private var isStoryModeSheetPresented: Bool = false

    init(viewModel: @autoclosure @escaping () -> ExploreViewModel = ExploreViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Layout.sectionSpacing) {
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
                        .font(.system(size: 18, weight: .regular))
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

            HStack(spacing: 20) {
                NavigationLink {
                    ExploreSearchView(viewModel: viewModel)
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .accessibilityIdentifier("explore.header.search")

                Button {
                    viewModel.showPlaceholder(message: AppLocalization.string("Open search to use filters."))
                } label: {
                    FilterButtonLabel()
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("explore.header.filter")
            }
            .buttonStyle(.plain)
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
                .frame(width: 48, height: 48)

            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
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
        VStack(alignment: .leading, spacing: AppTheme.Layout.sectionSpacing) {
            SectionHeader(title: "Latest") {
                viewModel.showPlaceholder(message: AppLocalization.string("Latest list actions are coming in v2."))
            }
            BookCoverStrip(books: feed.latest, size: .compact, showTitle: false) { book in
                selectedBook = book
            }

            FeaturedBookCard(
                book: feed.featured,
                onRead: { book in
                    viewModel.didTapRead(book)
                },
                onAdd: { book in
                    viewModel.didTapAdd(book)
                },
                onTapPoster: { book in
                    selectedBook = book
                }
            )

            SectionHeader(title: "Recommended") {
                viewModel.showPlaceholder(message: AppLocalization.string("Recommended actions are coming in v2."))
            }
            BookCoverStrip(books: feed.recommended, size: .regular, showTitle: true) { book in
                selectedBook = book
            }

            SectionHeader(title: "More Like This") {
                viewModel.showPlaceholder(message: AppLocalization.string("More-like-this actions are coming in v2."))
            }
            BookCoverStrip(books: feed.moreLikeThis, size: .regular, showTitle: true) { book in
                selectedBook = book
            }
        }
    }
}

#Preview {
    ExploreView()
}
