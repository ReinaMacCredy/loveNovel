import SwiftUI
import UIKit

struct LibraryView: View {
    @EnvironmentObject private var libraryStore: LibraryCollectionStore
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel = LibraryViewModel()
    @State private var selectedBook: Book?
    @State private var showSortSettings: Bool = false
    @State private var menuEntry: LibraryShelfEntry?
    @State private var alertMessage: String?

    @AppStorage(AppSettingsKey.libraryHistorySort)
    private var historySortRawValue: String = LibraryHistorySortOption.lastRead.rawValue

    @AppStorage(AppSettingsKey.libraryBookmarkSort)
    private var bookmarkSortRawValue: String = LibraryBookmarkSortOption.newestSaved.rawValue

    private var usesDarkPalette: Bool {
        colorScheme == .dark
    }

    private var pageBackground: Color {
        usesDarkPalette ? Color(red: 0.16, green: 0.17, blue: 0.19) : AppTheme.Colors.screenBackground
    }

    private var primaryTextColor: Color {
        usesDarkPalette ? Color.white.opacity(0.94) : AppTheme.Colors.textPrimary
    }

    private var secondaryTextColor: Color {
        usesDarkPalette ? Color.white.opacity(0.58) : AppTheme.Colors.textSecondary
    }

    private var segmentInactiveTextColor: Color {
        usesDarkPalette ? Color.white.opacity(0.36) : AppTheme.Colors.textSecondary.opacity(0.82)
    }

    private var rowDividerColor: Color {
        usesDarkPalette ? Color.white.opacity(0.06) : AppTheme.Colors.detailDivider
    }

    private var historySort: LibraryHistorySortOption {
        LibraryHistorySortOption(rawValue: historySortRawValue) ?? .lastRead
    }

    private var bookmarkSort: LibraryBookmarkSortOption {
        LibraryBookmarkSortOption(rawValue: bookmarkSortRawValue) ?? .newestSaved
    }

    private var displayedEntries: [LibraryShelfEntry] {
        viewModel.displayedEntries(
            historyEntries: libraryStore.historyEntries,
            bookmarkEntries: libraryStore.bookmarkEntries,
            historySort: historySort,
            bookmarkSort: bookmarkSort
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    header
                    segmentControl
                    content
                }
                .padding(.horizontal, AppTheme.Layout.horizontalInset)
                .padding(.top, 22)
                .padding(.bottom, 8)
            }
            .navigationDestination(item: $selectedBook) { book in
                NovelDetailView(book: book)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showSortSettings) {
            LibrarySortSettingsView()
        }
        .sheet(item: $menuEntry) { selectedEntry in
            LibraryRowMenuSheet(
                entry: currentEntry(for: selectedEntry.id) ?? selectedEntry,
                usesDarkPalette: usesDarkPalette,
                notificationEnabled: notificationBinding(for: selectedEntry.id),
                onDownload: {
                    alertMessage = AppLocalization.string("library.menu.download.coming_soon")
                },
                onRemove: {
                    libraryStore.remove(bookID: selectedEntry.id)
                    menuEntry = nil
                }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(usesDarkPalette ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color(.systemBackground))
        }
        .alert(
            "Coming Soon",
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        alertMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
        .accessibilityIdentifier("screen.library")
    }

    private var header: some View {
        HStack {
            Text("library.title.bookshelf")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(primaryTextColor)

            Spacer(minLength: 0)

            HStack(spacing: 18) {
                Button {
                    // Search is planned for v2.
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(primaryTextColor)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("library.header.search")
                .accessibilityLabel(Text("Library search"))

                Button {
                    showSortSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundStyle(primaryTextColor)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("library.header.sort_settings")
                .accessibilityLabel(Text("Library sort settings"))
            }
        }
    }

    private var segmentControl: some View {
        HStack(spacing: 26) {
            ForEach(LibraryViewModel.Segment.allCases) { segment in
                Button {
                    viewModel.selectedSegment = segment
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(segment.titleKey)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(viewModel.selectedSegment == segment ? primaryTextColor : segmentInactiveTextColor)

                        Capsule()
                            .fill(viewModel.selectedSegment == segment ? primaryTextColor : .clear)
                            .frame(width: 38, height: 3)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("library.segment.\(segment.id)")
            }
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private var content: some View {
        if displayedEntries.isEmpty {
            VStack(spacing: 14) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 74, weight: .regular))
                    .foregroundStyle(secondaryTextColor.opacity(0.7))

                VStack(spacing: 5) {
                    Text(viewModel.emptyLineOne)
                    Text(viewModel.emptyLineTwo)
                }
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(secondaryTextColor)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 52)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(displayedEntries) { entry in
                        libraryRow(entry)
                            .padding(.vertical, 13)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(rowDividerColor)
                                    .frame(height: 1)
                            }
                    }
                }
                .padding(.top, 14)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func libraryRow(_ entry: LibraryShelfEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            LibraryBookCover(book: entry.book)

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.book.title)
                    .font(.system(size: 24, weight: .regular))
                    .lineLimit(2)
                    .foregroundStyle(primaryTextColor)
                    .multilineTextAlignment(.leading)
                    .accessibilityIdentifier("library.row.title.\(entry.id)")

                Text(viewModel.progressLabel(for: entry))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(secondaryTextColor)
            }

            Spacer(minLength: 0)

            HStack(spacing: 16) {
                Button {
                    libraryStore.toggleMuted(for: entry.id)
                } label: {
                    Image(systemName: entry.isMuted ? "bell.slash.fill" : "bell.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(secondaryTextColor)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("library.row.toggle_mute.\(entry.id)")

                Button {
                    menuEntry = currentEntry(for: entry.id) ?? entry
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(secondaryTextColor)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("library.row.menu.\(entry.id)")
            }
            .padding(.top, 6)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedBook = entry.book
        }
        .accessibilityIdentifier("library.row.\(entry.id)")
    }

    private func currentEntry(for bookID: Book.ID) -> LibraryShelfEntry? {
        libraryStore.entry(for: bookID)
    }

    private func notificationBinding(for bookID: Book.ID) -> Binding<Bool> {
        Binding(
            get: {
                guard let entry = currentEntry(for: bookID) else {
                    return false
                }
                return entry.isMuted == false
            },
            set: { isEnabled in
                libraryStore.setNotificationEnabled(isEnabled, for: bookID)
            }
        )
    }
}

private struct LibraryBookCover: View {
    let book: Book
    var size: CGSize = CGSize(width: 60, height: 88)
    var cornerRadius: CGFloat = 8

    private var fallbackCover: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: book.accentHex),
                        Color(hex: book.accentHex).opacity(0.48),
                        Color.black.opacity(0.84)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .bottomLeading) {
                Text(String(book.title.prefix(1)))
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.leading, 6)
                    .padding(.bottom, 4)
            }
    }

    var body: some View {
        Group {
            if let uiImage = UIImage(named: "cover.\(book.id)") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let remoteCoverURL = remoteCoverURL {
                AsyncImage(url: remoteCoverURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        fallbackCover
                    }
                }
            } else {
                fallbackCover
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: Color.black.opacity(0.22), radius: 5, y: 2)
    }

    private var remoteCoverURL: URL? {
        URL(string: "https://picsum.photos/seed/lovenovel-\(book.id)/240/360")
    }
}

private struct LibraryRowMenuSheet: View {
    let entry: LibraryShelfEntry
    let usesDarkPalette: Bool
    @Binding var notificationEnabled: Bool
    let onDownload: () -> Void
    let onRemove: () -> Void

    private var titleColor: Color {
        usesDarkPalette ? Color.white.opacity(0.92) : AppTheme.Colors.textPrimary
    }

    private var subtitleColor: Color {
        usesDarkPalette ? Color.white.opacity(0.62) : AppTheme.Colors.textSecondary
    }

    private var iconColor: Color {
        usesDarkPalette ? Color.white.opacity(0.64) : AppTheme.Colors.textSecondary
    }

    private var dividerColor: Color {
        usesDarkPalette ? Color.white.opacity(0.08) : AppTheme.Colors.detailDivider
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                LibraryBookCover(
                    book: entry.book,
                    size: CGSize(width: 48, height: 70),
                    cornerRadius: 8
                )

                Text(entry.book.title)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(2)
                    .foregroundStyle(titleColor)
            }
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle()
                .fill(dividerColor)
                .frame(height: 1)

            actionButton(
                iconName: "icloud.and.arrow.down",
                labelKey: "library.menu.download",
                action: onDownload
            )

            actionButton(
                iconName: "trash",
                labelKey: "library.menu.remove",
                action: onRemove
            )

            HStack(spacing: 10) {
                Image(systemName: notificationEnabled ? "bell.fill" : "bell.slash.fill")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(iconColor)
                    .frame(width: 22)

                Text("library.menu.notifications")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(subtitleColor)

                Spacer(minLength: 0)

                Toggle("", isOn: $notificationEnabled)
                    .labelsHidden()
                    .tint(usesDarkPalette ? Color.white.opacity(0.35) : AppTheme.Colors.accentBlue.opacity(0.5))
            }
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.vertical, 12)
        }
        .accessibilityIdentifier("library.row.menu.sheet")
    }

    private func actionButton(
        iconName: String,
        labelKey: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(iconColor)
                    .frame(width: 22)

                Text(LocalizedStringKey(labelKey))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(subtitleColor)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(labelKey)
    }
}

#Preview("Populated Light") {
    LibraryView()
        .environmentObject(makeLibraryPreviewStore(populated: true))
        .preferredColorScheme(.light)
}

#Preview("Populated Dark") {
    LibraryView()
        .environmentObject(makeLibraryPreviewStore(populated: true))
        .preferredColorScheme(.dark)
}

#Preview("Empty") {
    LibraryView()
        .environmentObject(makeLibraryPreviewStore(populated: false))
}

#Preview("Row Menu Dark") {
    LibraryRowMenuSheet(
        entry: makeLibraryPreviewEntry(),
        usesDarkPalette: true,
        notificationEnabled: .constant(false),
        onDownload: {},
        onRemove: {}
    )
    .padding(.top, 8)
    .preferredColorScheme(.dark)
}

@MainActor
private func makeLibraryPreviewStore(populated: Bool) -> LibraryCollectionStore {
    let suiteName = "LibraryView.preview"
    let storageKey = "LibraryView.preview.collection"

    guard let defaults = UserDefaults(suiteName: suiteName) else {
        return LibraryCollectionStore(storageKey: storageKey)
    }

    defaults.removePersistentDomain(forName: suiteName)
    let store = LibraryCollectionStore(userDefaults: defaults, storageKey: storageKey)

    guard populated else {
        return store
    }

    _ = store.add(
        book: Book(
            id: "book-preview-1",
            title: "Biến Thành Mỹ Thiếu Nữ Cái Gì, Không Quan Trọng Rồi",
            author: "Tiên Hiệp",
            summary: "Preview summary",
            rating: 4.5,
            accentHex: "3A77B6"
        ),
        chapterCount: 517
    )

    _ = store.add(
        book: Book(
            id: "book-preview-2",
            title: "Khủng Bố Sống Lại",
            author: "Huyền Ảo",
            summary: "Preview summary",
            rating: 4.2,
            accentHex: "7A3E2E"
        ),
        chapterCount: 1606
    )

    _ = store.add(
        book: Book(
            id: "book-preview-3",
            title: "Đồ Cả Nhà Của Ta, Còn Muốn Để Cho Ta Khi Chính Đạo Chó?",
            author: "Hành Động",
            summary: "Preview summary",
            rating: 4.1,
            accentHex: "522C2C"
        ),
        chapterCount: 78
    )

    return store
}

private func makeLibraryPreviewEntry() -> LibraryShelfEntry {
    LibraryShelfEntry(
        id: "book-preview-1",
        book: Book(
            id: "book-preview-1",
            title: "Biến Thành Mỹ Thiếu Nữ Cái Gì, Không Quan Trọng Rồi",
            author: "Tiên Hiệp",
            summary: "Preview summary",
            rating: 4.5,
            accentHex: "3A77B6"
        ),
        lastReadChapter: 60,
        totalChapters: 517,
        savedAt: .now,
        lastReadAt: .now,
        isMuted: true
    )
}
