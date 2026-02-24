import Foundation
import SwiftUI
import LoveNovelCore
import LoveNovelDomain

struct LibraryShelfEntry: Codable, Identifiable, Sendable, Equatable, Hashable {
    let id: Book.ID
    let book: Book
    var lastReadChapter: Int
    var totalChapters: Int
    var savedAt: Date
    var lastReadAt: Date
    var isMuted: Bool
}

@MainActor
final class LibraryCollectionStore: ObservableObject {
    enum AddResult: Equatable {
        case added
        case alreadyExists
    }

    enum PersistenceMode {
        case immediate
        case debounced
    }

    @Published private(set) var historyEntries: [LibraryShelfEntry] = []
    @Published private(set) var bookmarkEntries: [LibraryShelfEntry] = []

    private let userDefaults: UserDefaults
    private let storageKey: String
    private var entriesByID: [Book.ID: LibraryShelfEntry] = [:]
    private var historyOrder: [Book.ID] = []
    private var bookmarkOrder: [Book.ID] = []
    private var pendingPersistenceTask: Task<Void, Never>?

    private static let progressPersistenceDebounceDuration: Duration = .milliseconds(250)

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = AppSettingsKey.libraryCollectionState
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        restore()
    }

    @discardableResult
    func add(book: Book, chapterCount: Int) -> AddResult {
        let normalizedChapterCount = max(chapterCount, 1)
        let now = Date()

        let addResult: AddResult
        if var existingEntry = entriesByID[book.id] {
            existingEntry.totalChapters = max(existingEntry.totalChapters, normalizedChapterCount)
            existingEntry.savedAt = now
            existingEntry.lastReadAt = now
            entriesByID[book.id] = existingEntry
            addResult = .alreadyExists
        } else {
            entriesByID[book.id] = LibraryShelfEntry(
                id: book.id,
                book: book,
                lastReadChapter: 0,
                totalChapters: normalizedChapterCount,
                savedAt: now,
                lastReadAt: now,
                isMuted: true
            )
            addResult = .added
        }

        moveToFront(book.id, in: &historyOrder)
        moveToFront(book.id, in: &bookmarkOrder)
        publish(persistence: .immediate)

        return addResult
    }

    func updateReadingProgress(
        for book: Book,
        chapterIndex: Int,
        chapterCount: Int?,
        persistence: PersistenceMode = .immediate
    ) {
        let now = Date()
        let requestedChapterCount = max(chapterCount ?? 0, 1)

        if var existingEntry = entriesByID[book.id] {
            let normalizedChapterCount = max(existingEntry.totalChapters, requestedChapterCount)
            let normalizedChapterIndex = min(max(chapterIndex, 0), normalizedChapterCount)

            existingEntry.totalChapters = normalizedChapterCount
            existingEntry.lastReadChapter = normalizedChapterIndex
            existingEntry.lastReadAt = now
            entriesByID[book.id] = existingEntry
            moveToFront(book.id, in: &historyOrder)
            publish(persistence: persistence)
            return
        }

        let normalizedChapterIndex = min(max(chapterIndex, 0), requestedChapterCount)
        entriesByID[book.id] = LibraryShelfEntry(
            id: book.id,
            book: book,
            lastReadChapter: normalizedChapterIndex,
            totalChapters: requestedChapterCount,
            savedAt: now,
            lastReadAt: now,
            isMuted: true
        )
        moveToFront(book.id, in: &historyOrder)
        publish(persistence: persistence)
    }

    func toggleMuted(for bookID: Book.ID) {
        guard var entry = entriesByID[bookID] else {
            return
        }

        entry.isMuted.toggle()
        entriesByID[bookID] = entry
        publish(persistence: .immediate)
    }

    func setNotificationEnabled(_ isEnabled: Bool, for bookID: Book.ID) {
        setMuted(!isEnabled, for: bookID)
    }

    func remove(bookID: Book.ID) {
        guard entriesByID.removeValue(forKey: bookID) != nil else {
            return
        }

        historyOrder.removeAll { $0 == bookID }
        bookmarkOrder.removeAll { $0 == bookID }
        publish(persistence: .immediate)
    }

    func flushPendingPersistence() {
        guard pendingPersistenceTask != nil else {
            return
        }

        pendingPersistenceTask?.cancel()
        pendingPersistenceTask = nil
        persistNow()
    }

    func entry(for bookID: Book.ID) -> LibraryShelfEntry? {
        entriesByID[bookID]
    }

    private func setMuted(_ isMuted: Bool, for bookID: Book.ID) {
        guard var entry = entriesByID[bookID] else {
            return
        }

        entry.isMuted = isMuted
        entriesByID[bookID] = entry
        publish(persistence: .immediate)
    }

    private func publish(persistence: PersistenceMode) {
        historyEntries = orderedEntries(from: historyOrder)
        bookmarkEntries = orderedEntries(from: bookmarkOrder)
        persist(using: persistence)
    }

    private func orderedEntries(from order: [Book.ID]) -> [LibraryShelfEntry] {
        var seenIDs = Set<Book.ID>()
        var orderedEntries: [LibraryShelfEntry] = []
        orderedEntries.reserveCapacity(order.count)

        for id in order {
            guard seenIDs.insert(id).inserted, let entry = entriesByID[id] else {
                continue
            }
            orderedEntries.append(entry)
        }

        return orderedEntries
    }

    private func restore() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return
        }

        guard let persistedState = try? JSONDecoder().decode(PersistedState.self, from: data) else {
            userDefaults.removeObject(forKey: storageKey)
            return
        }

        entriesByID = [:]
        for entry in persistedState.entries {
            mergeRestoredEntry(entry)
        }

        historyOrder = deduplicatedOrder(persistedState.historyOrder)
        bookmarkOrder = deduplicatedOrder(persistedState.bookmarkOrder)

        // Keep state resilient if older snapshots are missing order ids.
        var historyIDSet = Set(historyOrder)
        for id in entriesByID.keys where historyIDSet.insert(id).inserted {
            historyOrder.append(id)
        }
        var bookmarkIDSet = Set(bookmarkOrder)
        for id in entriesByID.keys where bookmarkIDSet.insert(id).inserted {
            bookmarkOrder.append(id)
        }

        historyEntries = orderedEntries(from: historyOrder)
        bookmarkEntries = orderedEntries(from: bookmarkOrder)
    }

    private func mergeRestoredEntry(_ entry: LibraryShelfEntry) {
        let incomingEntry = normalizedEntry(entry)

        guard var existingEntry = entriesByID[incomingEntry.id] else {
            entriesByID[incomingEntry.id] = incomingEntry
            return
        }

        let mergedTotalChapters = max(existingEntry.totalChapters, incomingEntry.totalChapters)
        let mergedLastReadChapter = min(
            max(existingEntry.lastReadChapter, incomingEntry.lastReadChapter),
            mergedTotalChapters
        )
        let prefersIncomingMetadata = incomingEntry.lastReadAt >= existingEntry.lastReadAt

        existingEntry = LibraryShelfEntry(
            id: existingEntry.id,
            book: prefersIncomingMetadata ? incomingEntry.book : existingEntry.book,
            lastReadChapter: mergedLastReadChapter,
            totalChapters: mergedTotalChapters,
            savedAt: max(existingEntry.savedAt, incomingEntry.savedAt),
            lastReadAt: max(existingEntry.lastReadAt, incomingEntry.lastReadAt),
            isMuted: existingEntry.isMuted && incomingEntry.isMuted
        )

        entriesByID[incomingEntry.id] = existingEntry
    }

    private func normalizedEntry(_ entry: LibraryShelfEntry) -> LibraryShelfEntry {
        let normalizedTotalChapters = max(entry.totalChapters, 1)
        let normalizedLastReadChapter = min(max(entry.lastReadChapter, 0), normalizedTotalChapters)

        return LibraryShelfEntry(
            id: entry.id,
            book: entry.book,
            lastReadChapter: normalizedLastReadChapter,
            totalChapters: normalizedTotalChapters,
            savedAt: entry.savedAt,
            lastReadAt: entry.lastReadAt,
            isMuted: entry.isMuted
        )
    }

    private func deduplicatedOrder(_ order: [Book.ID]) -> [Book.ID] {
        var seenIDs = Set<Book.ID>()

        return order.filter { id in
            guard entriesByID[id] != nil else {
                return false
            }

            return seenIDs.insert(id).inserted
        }
    }

    private func persist(using persistence: PersistenceMode) {
        switch persistence {
        case .immediate:
            pendingPersistenceTask?.cancel()
            pendingPersistenceTask = nil
            persistNow()
        case .debounced:
            scheduleDebouncedPersistence()
        }
    }

    private func scheduleDebouncedPersistence() {
        pendingPersistenceTask?.cancel()
        pendingPersistenceTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: Self.progressPersistenceDebounceDuration)
            } catch {
                return
            }

            guard let self, !Task.isCancelled else {
                return
            }

            self.persistNow()
            self.pendingPersistenceTask = nil
        }
    }

    private func persistNow() {
        let state = PersistedState(
            entries: Array(entriesByID.values),
            historyOrder: historyOrder,
            bookmarkOrder: bookmarkOrder
        )

        guard let data = try? JSONEncoder().encode(state) else {
            return
        }

        userDefaults.set(data, forKey: storageKey)
    }

    private func moveToFront(_ id: Book.ID, in array: inout [Book.ID]) {
        array.removeAll { $0 == id }
        array.insert(id, at: 0)
    }

    private struct PersistedState: Codable, Sendable {
        let entries: [LibraryShelfEntry]
        let historyOrder: [Book.ID]
        let bookmarkOrder: [Book.ID]
    }
}
