import SwiftUI

@MainActor
final class LibraryViewModel: ObservableObject {
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

    @Published var selectedSegment: Segment = .history

    var emptyLineOne: String {
        AppLocalization.string("library.empty.line.one")
    }

    var emptyLineTwo: String {
        AppLocalization.string("library.empty.line.two")
    }
}
