import Foundation
import Testing
@testable import LoveNovel

@MainActor
@Suite("Library collection store tests", .tags(.fast, .settings))
struct LibraryCollectionStoreTests {
    @Test("Add inserts entry into history and bookmark lists")
    func addInsertsEntryIntoHistoryAndBookmarkLists() throws {
        let (store, defaults, suiteName) = Self.makeStore()
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let result = store.add(book: Self.sampleBook, chapterCount: 517)

        #expect(result == .added)
        #expect(store.historyEntries.count == 1)
        #expect(store.bookmarkEntries.count == 1)

        let historyEntry = try #require(store.historyEntries.first)
        #expect(historyEntry.id == Self.sampleBook.id)
        #expect(historyEntry.totalChapters == 517)
        #expect(historyEntry.lastReadChapter == 0)
    }

    @Test("Adding duplicate keeps one entry and updates max chapter count")
    func addingDuplicateKeepsOneEntryAndUpdatesMaxChapterCount() throws {
        let (store, defaults, suiteName) = Self.makeStore()
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let firstResult = store.add(book: Self.sampleBook, chapterCount: 120)
        let secondResult = store.add(book: Self.sampleBook, chapterCount: 680)

        #expect(firstResult == .added)
        #expect(secondResult == .alreadyExists)
        #expect(store.historyEntries.count == 1)
        #expect(store.bookmarkEntries.count == 1)

        let updatedEntry = try #require(store.historyEntries.first)
        #expect(updatedEntry.totalChapters == 680)
    }

    @Test("Reading progress updates the stored chapter and keeps saved date")
    func readingProgressUpdatesStoredChapterAndKeepsSavedDate() throws {
        let (store, defaults, suiteName) = Self.makeStore()
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        store.add(book: Self.sampleBook, chapterCount: 517)
        let initialEntry = try #require(store.entry(for: Self.sampleBook.id))
        let initialSavedAt = initialEntry.savedAt

        store.updateReadingProgress(
            for: Self.sampleBook,
            chapterIndex: 60,
            chapterCount: 517
        )

        let updatedEntry = try #require(store.entry(for: Self.sampleBook.id))
        #expect(updatedEntry.lastReadChapter == 60)
        #expect(updatedEntry.totalChapters == 517)
        #expect(updatedEntry.savedAt == initialSavedAt)
        #expect(updatedEntry.lastReadAt >= initialSavedAt)
    }

    @Test("Reading progress auto-creates an entry and clamps to chapter bounds")
    func readingProgressAutoCreatesEntryAndClampsToChapterBounds() throws {
        let (store, defaults, suiteName) = Self.makeStore()
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        store.updateReadingProgress(
            for: Self.sampleBook,
            chapterIndex: 999,
            chapterCount: 78
        )

        #expect(store.historyEntries.count == 1)
        #expect(store.bookmarkEntries.isEmpty)

        let createdEntry = try #require(store.entry(for: Self.sampleBook.id))
        #expect(createdEntry.lastReadChapter == 78)
        #expect(createdEntry.totalChapters == 78)
    }

    @Test("Debounced reading progress updates memory immediately and persists on flush")
    func debouncedReadingProgressUpdatesMemoryImmediatelyAndPersistsOnFlush() throws {
        let storageKey = "tests.library.collection.\(UUID().uuidString)"
        let suiteName = "LibraryCollectionStoreTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create isolated UserDefaults suite.")
            return
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = LibraryCollectionStore(userDefaults: defaults, storageKey: storageKey)
        store.add(book: Self.sampleBook, chapterCount: 517)

        store.updateReadingProgress(
            for: Self.sampleBook,
            chapterIndex: 12,
            chapterCount: 517,
            persistence: .debounced
        )

        let inMemoryEntry = try #require(store.entry(for: Self.sampleBook.id))
        #expect(inMemoryEntry.lastReadChapter == 12)

        let restoredBeforeFlush = LibraryCollectionStore(userDefaults: defaults, storageKey: storageKey)
        let beforeFlushEntry = try #require(restoredBeforeFlush.entry(for: Self.sampleBook.id))
        #expect(beforeFlushEntry.lastReadChapter == 0)

        store.updateReadingProgress(
            for: Self.sampleBook,
            chapterIndex: 42,
            chapterCount: 517,
            persistence: .debounced
        )
        store.flushPendingPersistence()

        let restoredAfterFlush = LibraryCollectionStore(userDefaults: defaults, storageKey: storageKey)
        let afterFlushEntry = try #require(restoredAfterFlush.entry(for: Self.sampleBook.id))
        #expect(afterFlushEntry.lastReadChapter == 42)
    }

    @Test("Muted icon state toggles for a stored book")
    func mutedIconStateTogglesForAStoredBook() throws {
        let (store, defaults, suiteName) = Self.makeStore()
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        store.add(book: Self.sampleBook, chapterCount: 517)

        let initialEntry = try #require(store.historyEntries.first)
        #expect(initialEntry.isMuted)

        store.toggleMuted(for: Self.sampleBook.id)

        let entryAfterToggle = try #require(store.historyEntries.first)
        #expect(entryAfterToggle.isMuted == false)
    }

    @Test("Stored entries restore from UserDefaults snapshot")
    func storedEntriesRestoreFromUserDefaultsSnapshot() throws {
        let storageKey = "tests.library.collection.\(UUID().uuidString)"
        let suiteName = "LibraryCollectionStoreTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create isolated UserDefaults suite.")
            return
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let firstStore = LibraryCollectionStore(userDefaults: defaults, storageKey: storageKey)
        firstStore.add(book: Self.sampleBook, chapterCount: 517)

        let restoredStore = LibraryCollectionStore(userDefaults: defaults, storageKey: storageKey)
        let restoredEntry = try #require(restoredStore.historyEntries.first)

        #expect(restoredStore.historyEntries.count == 1)
        #expect(restoredStore.bookmarkEntries.count == 1)
        #expect(restoredEntry.book.title == Self.sampleBook.title)
    }

    @Test("Restore merges duplicate persisted IDs without crashing")
    func restoreMergesDuplicatePersistedIDsWithoutCrashing() throws {
        let storageKey = "tests.library.collection.\(UUID().uuidString)"
        let suiteName = "LibraryCollectionStoreTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create isolated UserDefaults suite.")
            return
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let firstStore = LibraryCollectionStore(userDefaults: defaults, storageKey: storageKey)
        firstStore.add(book: Self.sampleBook, chapterCount: 80)
        firstStore.updateReadingProgress(for: Self.sampleBook, chapterIndex: 12, chapterCount: 80)

        guard let baselineData = defaults.data(forKey: storageKey) else {
            Issue.record("Missing baseline persisted data.")
            return
        }
        guard var payload = try JSONSerialization.jsonObject(with: baselineData) as? [String: Any] else {
            Issue.record("Could not decode baseline payload.")
            return
        }
        guard var entries = payload["entries"] as? [[String: Any]], var duplicateEntry = entries.first else {
            Issue.record("Could not read baseline entries.")
            return
        }

        duplicateEntry["totalChapters"] = 388
        duplicateEntry["lastReadChapter"] = 320
        duplicateEntry["isMuted"] = false
        if let lastReadAt = duplicateEntry["lastReadAt"] as? Double {
            duplicateEntry["lastReadAt"] = lastReadAt + 120
        }
        if let savedAt = duplicateEntry["savedAt"] as? Double {
            duplicateEntry["savedAt"] = savedAt + 120
        }

        entries.append(duplicateEntry)
        payload["entries"] = entries
        payload["historyOrder"] = [Self.sampleBook.id, Self.sampleBook.id]
        payload["bookmarkOrder"] = [Self.sampleBook.id, Self.sampleBook.id]

        let duplicatePayloadData = try JSONSerialization.data(withJSONObject: payload)
        defaults.set(duplicatePayloadData, forKey: storageKey)

        let restoredStore = LibraryCollectionStore(userDefaults: defaults, storageKey: storageKey)
        let restoredEntry = try #require(restoredStore.entry(for: Self.sampleBook.id))

        #expect(restoredStore.historyEntries.count == 1)
        #expect(restoredStore.bookmarkEntries.count == 1)
        #expect(restoredEntry.totalChapters == 388)
        #expect(restoredEntry.lastReadChapter == 320)
        #expect(restoredEntry.isMuted == false)
    }

    @Test("Notification toggle updates muted state explicitly")
    func notificationToggleUpdatesMutedStateExplicitly() throws {
        let (store, defaults, suiteName) = Self.makeStore()
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        store.add(book: Self.sampleBook, chapterCount: 517)

        store.setNotificationEnabled(true, for: Self.sampleBook.id)
        let unmutedEntry = try #require(store.entry(for: Self.sampleBook.id))
        #expect(unmutedEntry.isMuted == false)

        store.setNotificationEnabled(false, for: Self.sampleBook.id)
        let mutedEntry = try #require(store.entry(for: Self.sampleBook.id))
        #expect(mutedEntry.isMuted)
    }

    @Test("Remove deletes entry from both library segments")
    func removeDeletesEntryFromBothLibrarySegments() {
        let (store, defaults, suiteName) = Self.makeStore()
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        store.add(book: Self.sampleBook, chapterCount: 517)
        #expect(store.historyEntries.count == 1)
        #expect(store.bookmarkEntries.count == 1)

        store.remove(bookID: Self.sampleBook.id)

        #expect(store.historyEntries.isEmpty)
        #expect(store.bookmarkEntries.isEmpty)
        #expect(store.entry(for: Self.sampleBook.id) == nil)
    }

    private static func makeStore() -> (LibraryCollectionStore, UserDefaults, String) {
        let suiteName = "LibraryCollectionStoreTests.\(UUID().uuidString)"
        let storageKey = "tests.library.collection.\(UUID().uuidString)"

        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Could not create isolated UserDefaults suite.")
        }

        defaults.removePersistentDomain(forName: suiteName)
        let store = LibraryCollectionStore(userDefaults: defaults, storageKey: storageKey)
        return (store, defaults, suiteName)
    }

    private static let sampleBook = Book(
        id: "demo-book",
        title: "Biến Thành Mỹ Thiếu Nữ Về Sau",
        author: "Tiên Hiệp",
        summary: "A sample summary",
        rating: 4.7,
        accentHex: "246CA2"
    )
}
