import SwiftUI

struct ExploreSearchView: View {
    @ObservedObject var viewModel: ExploreViewModel

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFieldFocused: Bool
    @State private var query: String = ""
    @State private var selectedBook: Book?
    @State private var searchPhase: SearchPhase = .idle

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .overlay(AppTheme.Colors.detailDivider)
            Text("explore.search.filter.unavailable_reason")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Layout.horizontalInset)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .accessibilityIdentifier("explore.search.filter.unavailable_reason")
            searchContent
        }
        .background(AppTheme.Colors.screenBackground.ignoresSafeArea())
        .task(id: query) {
            await runSearch()
        }
        .task {
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else {
                return
            }

            isSearchFieldFocused = true
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear {
            isSearchFieldFocused = false
        }
        .navigationDestination(item: $selectedBook) { book in
            NovelDetailView(book: book)
        }
        .accessibilityIdentifier("screen.explore.search")
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                isSearchFieldFocused = false
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("explore.search.back")

            TextField("Tim", text: $query)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .keyboardType(.default)
                .focused($isSearchFieldFocused)
                .submitLabel(.search)
                .accessibilityIdentifier("explore.search.input")

            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(width: 24, height: 24)
                .accessibilityIdentifier("explore.search.submit")

            Button(action: {}) {
                FilterButtonLabel()
            }
            .buttonStyle(.plain)
            .disabled(true)
            .opacity(0.45)
            .accessibilityIdentifier("explore.search.filter")
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
        .frame(height: 56)
    }

    @ViewBuilder
    private var searchContent: some View {
        switch searchPhase {
        case .idle:
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .searching:
            VStack(spacing: 10) {
                ProgressView()
                    .tint(AppTheme.Colors.accentBlue)
                Text("Searching...")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 30)

        case let .results(books):
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(books) { book in
                        Button {
                            selectedBook = book
                        } label: {
                            SearchBookRow(book: book)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("explore.search.result.\(book.id)")
                    }
                }
                .padding(.horizontal, AppTheme.Layout.horizontalInset)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

        case .empty:
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
        }
    }

    private func runSearch() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchPhase = .idle
            return
        }

        searchPhase = .searching

        do {
            try await Task.sleep(for: .milliseconds(250))
        } catch {
            return
        }

        let books = await viewModel.searchBooks(matching: trimmedQuery)
        guard !Task.isCancelled else {
            return
        }

        searchPhase = books.isEmpty ? .empty : .results(books)
    }
}

private struct ExploreFilterSheet: View {
    @Binding var isPresented: Bool

    @State private var selectedSort: String = "Mới lên chương"
    @State private var selectedTypes: Set<String> = []
    @State private var selectedGenders: Set<String> = []
    @State private var selectedStatuses: Set<String> = []

    private let sortRows: [[String]] = [
        ["Mới lên chương", "Mới đăng", "Lượt đọc", "Lượt đọc tuần"],
        ["Lượt đề cử", "Lượt đề cử tuần", "Lượt bình luận"],
        ["Lượt bình luận tuần", "Lượt đánh dấu", "Lượt đánh giá"],
        ["Điểm đánh giá", "Số chương", "Lượt mở khóa", "Tên truyện"]
    ]

    private let typeOptions: [String] = ["Chuyên ngữ", "Sáng tác"]
    private let genderOptions: [String] = ["Truyện nam", "Truyện nữ"]
    private let statusOptions: [String] = ["Còn tiếp", "Hoàn thành", "Tạm dừng"]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            filterSection(titleKey: "Sắp xếp") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sortRows, id: \.self) { row in
                        HStack(spacing: 16) {
                            ForEach(row, id: \.self) { option in
                                FilterTextButton(
                                    title: option,
                                    isSelected: selectedSort == option
                                ) {
                                    selectedSort = option
                                }
                            }
                        }
                    }
                }
            }

            filterSection(titleKey: "Loại") {
                HStack(spacing: 16) {
                    ForEach(typeOptions, id: \.self) { option in
                        FilterTextButton(
                            title: option,
                            isSelected: selectedTypes.contains(option)
                        ) {
                            toggle(option, in: &selectedTypes)
                        }
                    }
                }
            }

            filterSection(titleKey: "Giới tính") {
                HStack(spacing: 16) {
                    ForEach(genderOptions, id: \.self) { option in
                        FilterTextButton(
                            title: option,
                            isSelected: selectedGenders.contains(option)
                        ) {
                            toggle(option, in: &selectedGenders)
                        }
                    }
                }
            }

            filterSection(titleKey: "Tình trạng") {
                HStack(spacing: 16) {
                    ForEach(statusOptions, id: \.self) { option in
                        FilterTextButton(
                            title: option,
                            isSelected: selectedStatuses.contains(option)
                        ) {
                            toggle(option, in: &selectedStatuses)
                        }
                    }
                }
            }

            Spacer(minLength: 6)

            Button {
                isPresented = false
            } label: {
                Text("Gửi")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 430, alignment: .topLeading)
        .background(AppTheme.Colors.screenBackground)
        .overlay(alignment: .top) {
            Divider()
                .overlay(AppTheme.Colors.detailDivider)
        }
        .accessibilityIdentifier("explore.search.filter.sheet")
    }

    private func filterSection<Content: View>(titleKey: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            content()
        }
    }

    private func toggle(_ value: String, in set: inout Set<String>) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }
}

private struct FilterTextButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            Text(LocalizedStringKey(title))
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(isSelected ? AppTheme.Colors.accentBlue : AppTheme.Colors.textSecondary)
                .underline(isSelected, color: AppTheme.Colors.accentBlue)
                .lineLimit(1)
        }
        .buttonStyle(.plain)
    }
}

private enum SearchPhase: Equatable {
    case idle
    case searching
    case results([Book])
    case empty
}

private struct SearchBookRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: book.accentHex), Color.black.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
                .overlay {
                    Text(String(book.title.prefix(1)))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(book.author)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }
}

#Preview {
    NavigationStack {
        ExploreSearchView(viewModel: ExploreViewModel())
    }
}
