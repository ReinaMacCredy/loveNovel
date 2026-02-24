import Foundation
import LoveNovelCore
import LoveNovelDomain

protocol ResolveDisplayedLibraryEntriesUseCase: Sendable {
    func execute(
        selectedSegment: LibraryViewModel.Segment,
        historyEntries: [LibraryShelfEntry],
        bookmarkEntries: [LibraryShelfEntry],
        historySort: LibraryHistorySortOption,
        bookmarkSort: LibraryBookmarkSortOption
    ) -> [LibraryShelfEntry]
}

struct DefaultResolveDisplayedLibraryEntriesUseCase: ResolveDisplayedLibraryEntriesUseCase {
    func execute(
        selectedSegment: LibraryViewModel.Segment,
        historyEntries: [LibraryShelfEntry],
        bookmarkEntries: [LibraryShelfEntry],
        historySort: LibraryHistorySortOption,
        bookmarkSort: LibraryBookmarkSortOption
    ) -> [LibraryShelfEntry] {
        switch selectedSegment {
        case .history:
            return sortedHistoryEntries(historyEntries, option: historySort)
        case .bookmark:
            return sortedBookmarkEntries(bookmarkEntries, option: bookmarkSort)
        }
    }

    private func sortedHistoryEntries(
        _ entries: [LibraryShelfEntry],
        option: LibraryHistorySortOption
    ) -> [LibraryShelfEntry] {
        switch option {
        case .newestChapter:
            return entries.sorted { lhs, rhs in
                if lhs.totalChapters == rhs.totalChapters {
                    return lhs.lastReadAt > rhs.lastReadAt
                }

                return lhs.totalChapters > rhs.totalChapters
            }
        case .lastRead:
            return entries.sorted { lhs, rhs in
                lhs.lastReadAt > rhs.lastReadAt
            }
        case .title:
            return entries.sorted { lhs, rhs in
                lhs.book.title.localizedCaseInsensitiveCompare(rhs.book.title) == .orderedAscending
            }
        }
    }

    private func sortedBookmarkEntries(
        _ entries: [LibraryShelfEntry],
        option: LibraryBookmarkSortOption
    ) -> [LibraryShelfEntry] {
        switch option {
        case .newestChapter:
            return entries.sorted { lhs, rhs in
                if lhs.totalChapters == rhs.totalChapters {
                    return lhs.savedAt > rhs.savedAt
                }

                return lhs.totalChapters > rhs.totalChapters
            }
        case .newestSaved:
            return entries.sorted { lhs, rhs in
                lhs.savedAt > rhs.savedAt
            }
        case .title:
            return entries.sorted { lhs, rhs in
                lhs.book.title.localizedCaseInsensitiveCompare(rhs.book.title) == .orderedAscending
            }
        }
    }
}

protocol FilterLibraryEntriesUseCase: Sendable {
    func execute(_ entries: [LibraryShelfEntry], query: String) -> [LibraryShelfEntry]
}

struct DefaultFilterLibraryEntriesUseCase: FilterLibraryEntriesUseCase {
    func execute(_ entries: [LibraryShelfEntry], query: String) -> [LibraryShelfEntry] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return entries
        }

        return entries.filter { entry in
            entry.book.title.localizedStandardContains(trimmedQuery)
            || entry.book.author.localizedStandardContains(trimmedQuery)
            || entry.book.summary.localizedStandardContains(trimmedQuery)
        }
    }
}

protocol FormatLibraryProgressLabelUseCase: Sendable {
    func execute(entry: LibraryShelfEntry) -> String
}

struct DefaultFormatLibraryProgressLabelUseCase: FormatLibraryProgressLabelUseCase {
    func execute(entry: LibraryShelfEntry) -> String {
        AppLocalization.format("library.progress.read", entry.lastReadChapter, entry.totalChapters)
    }
}
