import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    enum Segment: String, CaseIterable, Identifiable {
        case history = "History"
        case bookmark = "Bookmark"

        var id: String {
            rawValue
        }
    }

    @Published var selectedSegment: Segment = .history

    let emptyLineOne: String = "All Books you have read would be here"
    let emptyLineTwo: String = "Time to Explore"
}
