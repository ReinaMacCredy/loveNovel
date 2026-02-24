import Foundation
import SwiftUI
import LoveNovelCore
import LoveNovelDomain

@MainActor
public final class LibraryViewModel: ObservableObject {
    enum Segment: String, CaseIterable, Identifiable {
        case history = "History"
        case bookmark = "Bookmark"

        var id: String {
            rawValue
        }

        var titleKey: LocalizedStringKey {
            LocalizedStringKey(rawValue)
        }
    }

    private let resolveDisplayedEntriesUseCase: any ResolveDisplayedLibraryEntriesUseCase
    private let filterEntriesUseCase: any FilterLibraryEntriesUseCase
    private let formatProgressLabelUseCase: any FormatLibraryProgressLabelUseCase

    @Published var selectedSegment: Segment = .history

    init(
        resolveDisplayedEntriesUseCase: any ResolveDisplayedLibraryEntriesUseCase = DefaultResolveDisplayedLibraryEntriesUseCase(),
        filterEntriesUseCase: any FilterLibraryEntriesUseCase = DefaultFilterLibraryEntriesUseCase(),
        formatProgressLabelUseCase: any FormatLibraryProgressLabelUseCase = DefaultFormatLibraryProgressLabelUseCase()
    ) {
        self.resolveDisplayedEntriesUseCase = resolveDisplayedEntriesUseCase
        self.filterEntriesUseCase = filterEntriesUseCase
        self.formatProgressLabelUseCase = formatProgressLabelUseCase
    }

    public static func live() -> LibraryViewModel {
        LibraryViewModel(
            resolveDisplayedEntriesUseCase: DefaultResolveDisplayedLibraryEntriesUseCase(),
            filterEntriesUseCase: DefaultFilterLibraryEntriesUseCase(),
            formatProgressLabelUseCase: DefaultFormatLibraryProgressLabelUseCase()
        )
    }

    var emptyLineOne: String {
        AppLocalization.string("library.empty.line.one")
    }

    var emptyLineTwo: String {
        AppLocalization.string("library.empty.line.two")
    }

    func displayedEntries(
        historyEntries: [LibraryShelfEntry],
        bookmarkEntries: [LibraryShelfEntry],
        historySort: LibraryHistorySortOption,
        bookmarkSort: LibraryBookmarkSortOption
    ) -> [LibraryShelfEntry] {
        resolveDisplayedEntriesUseCase.execute(
            selectedSegment: selectedSegment,
            historyEntries: historyEntries,
            bookmarkEntries: bookmarkEntries,
            historySort: historySort,
            bookmarkSort: bookmarkSort
        )
    }

    func progressLabel(for entry: LibraryShelfEntry) -> String {
        formatProgressLabelUseCase.execute(entry: entry)
    }

    func filteredEntries(
        _ entries: [LibraryShelfEntry],
        matching query: String
    ) -> [LibraryShelfEntry] {
        filterEntriesUseCase.execute(entries, query: query)
    }
}
