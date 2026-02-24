import SwiftUI

struct ExploreAllStoriesView: View {
    @ObservedObject var viewModel: ExploreViewModel
    private let container: AppContainer

    @Environment(\.dismiss) private var dismiss
    @State private var selectedBook: Book?
    @State private var phase: Phase = .idle
    @State private var listItems: [ExploreViewModel.AllStoriesListItem] = []

    init(
        viewModel: ExploreViewModel,
        container: AppContainer = .live
    ) {
        self.viewModel = viewModel
        self.container = container
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .overlay(AppTheme.Colors.detailDivider)

            content
        }
        .background(AppTheme.Colors.screenBackground.ignoresSafeArea())
        .task {
            await loadList()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedBook) { book in
            NovelDetailView(book: book, container: container)
        }
        .accessibilityIdentifier("screen.explore.all_stories")
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("explore.all_stories.back")

            Spacer()

            Text("Danh Sách Truyện")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idle, .loading:
            VStack(spacing: 10) {
                ProgressView()
                    .tint(AppTheme.Colors.accentBlue)
                Text("Loading stories...")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 20)

        case .failed:
            VStack(spacing: 10) {
                Text(viewModel.errorMessage ?? "Could not load stories.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Try Again") {
                    Task {
                        await loadList(force: true)
                    }
                }
                .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)

        case .loaded:
            if listItems.isEmpty {
                VStack(spacing: 8) {
                    Text("No stories found")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text("Try a different title or author.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 30)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(listItems) { item in
                            Button {
                                selectedBook = item.book
                            } label: {
                                AllStoriesRow(item: item)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("explore.all_stories.row.\(item.id)")
                        }
                    }
                    .padding(.horizontal, AppTheme.Layout.horizontalInset)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func loadList(force: Bool = false) async {
        if phase == .loading {
            return
        }

        if phase == .loaded && !force {
            return
        }

        phase = .loading

        let items = await viewModel.allStoriesListItems()
        guard !Task.isCancelled else {
            phase = .idle
            return
        }

        listItems = items

        if items.isEmpty, viewModel.phase == .failed {
            phase = .failed
            return
        }

        phase = .loaded
    }
}

private struct AllStoriesRow: View {
    let item: ExploreViewModel.AllStoriesListItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: item.book.accentHex),
                            Color(hex: item.book.accentHex).opacity(0.45),
                            Color.black.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 74, height: 100)
                .overlay(alignment: .bottomLeading) {
                    Text(String(item.book.title.prefix(1)))
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.leading, 8)
                        .padding(.bottom, 6)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.categoryTag)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.accentBlue.opacity(0.75))
                        .lineLimit(1)

                    Text(item.rankTag)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.accentBlue.opacity(0.75))
                        .lineLimit(1)
                }

                Text(item.book.title)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(item.book.author)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.24))
                    Text(String(format: "%.1f", item.book.rating))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.24))
                        .padding(.leading, 2)
                    Text("\(item.chapterCount)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    Text(item.viewsLabel)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum Phase: Equatable {
    case idle
    case loading
    case loaded
    case failed
}

#Preview {
    NavigationStack {
        let container = AppContainer.live
        ExploreAllStoriesView(
            viewModel: container.makeExploreViewModel(),
            container: container
        )
    }
    .environmentObject(LibraryCollectionStore(storageKey: "ExploreAllStoriesView.preview.collection"))
}
