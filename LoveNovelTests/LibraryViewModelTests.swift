import Foundation
import Testing
@testable import LoveNovel

@MainActor
@Suite("Library view model tests", .tags(.viewModel))
struct LibraryViewModelTests {
    @Test("Filtered entries returns all rows for empty query")
    func filteredEntriesReturnsAllRowsForEmptyQuery() {
        let viewModel = LibraryViewModel()

        let results = viewModel.filteredEntries(Self.sampleEntries, matching: "   ")

        #expect(results.map(\.id) == Self.sampleEntries.map(\.id))
    }

    @Test("Filtered entries matches title, author, and summary")
    func filteredEntriesMatchesTitleAuthorAndSummary() {
        let viewModel = LibraryViewModel()

        let titleMatch = viewModel.filteredEntries(Self.sampleEntries, matching: "Seeded")
        #expect(titleMatch.map(\.id) == ["seeded"])

        let authorMatch = viewModel.filteredEntries(Self.sampleEntries, matching: "Another Author")
        #expect(authorMatch.map(\.id) == ["secondary"])

        let summaryMatch = viewModel.filteredEntries(Self.sampleEntries, matching: "offline")
        #expect(summaryMatch.map(\.id) == ["seeded"])
    }

    @Test("Filtered entries returns empty when no rows match")
    func filteredEntriesReturnsEmptyWhenNoRowsMatch() {
        let viewModel = LibraryViewModel()

        let results = viewModel.filteredEntries(Self.sampleEntries, matching: "no-match-query")

        #expect(results.isEmpty)
    }

    private static let sampleEntries: [LibraryShelfEntry] = [
        LibraryShelfEntry(
            id: "seeded",
            book: Book(
                id: "seeded",
                title: "Seeded Library Novel",
                author: "UITest",
                summary: "A seeded story for offline library search.",
                rating: 4.6,
                accentHex: "2A5E96"
            ),
            lastReadChapter: 12,
            totalChapters: 120,
            savedAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastReadAt: Date(timeIntervalSince1970: 1_700_100_000),
            isMuted: true
        ),
        LibraryShelfEntry(
            id: "secondary",
            book: Book(
                id: "secondary",
                title: "Another Story",
                author: "Another Author",
                summary: "Supplemental description text.",
                rating: 4.2,
                accentHex: "4B3A91"
            ),
            lastReadChapter: 6,
            totalChapters: 60,
            savedAt: Date(timeIntervalSince1970: 1_699_000_000),
            lastReadAt: Date(timeIntervalSince1970: 1_699_100_000),
            isMuted: false
        )
    ]
}
