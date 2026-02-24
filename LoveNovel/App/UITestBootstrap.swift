import Foundation
import LoveNovelCore
import LoveNovelDomain

public enum UITestBootstrap {
    private static let seedLibraryFlag = "-uitest.seedLibrary"
    private static let resetLibraryFlag = "-uitest.resetLibrary"

    public static func applyIfNeeded(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        userDefaults: UserDefaults = .standard
    ) {
        if arguments.contains(resetLibraryFlag) {
            userDefaults.removeObject(forKey: AppSettingsKey.libraryCollectionState)
        }

        guard arguments.contains(seedLibraryFlag) else {
            return
        }

        let seedBook = Book(
            id: "ui-seed-book",
            title: "Seeded Library Novel",
            author: "UITest",
            summary: "Seeded summary",
            rating: 4.8,
            accentHex: "2A5E96"
        )

        let seededEntry = LibraryShelfEntry(
            id: seedBook.id,
            book: seedBook,
            lastReadChapter: 12,
            totalChapters: 120,
            savedAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastReadAt: Date(timeIntervalSince1970: 1_700_100_000),
            isMuted: true
        )

        let seededState = PersistedLibraryState(
            entries: [seededEntry],
            historyOrder: [seededEntry.id],
            bookmarkOrder: [seededEntry.id]
        )

        guard let data = try? JSONEncoder().encode(seededState) else {
            return
        }

        userDefaults.set(data, forKey: AppSettingsKey.libraryCollectionState)
    }

    private struct PersistedLibraryState: Codable, Sendable {
        let entries: [LibraryShelfEntry]
        let historyOrder: [Book.ID]
        let bookmarkOrder: [Book.ID]
    }
}
