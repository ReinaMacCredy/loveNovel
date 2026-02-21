import SwiftUI

enum AppSettingsKey {
    static let preferredLanguage = "settings.preferredLanguage"
    static let readerDarkMode = "settings.reader.darkMode"
    static let readerLightTheme = "settings.reader.lightTheme"
    static let readerDarkTheme = "settings.reader.darkTheme"
    static let libraryHistorySort = "settings.library.historySort"
    static let libraryBookmarkSort = "settings.library.bookmarkSort"
    static let libraryCollectionState = "settings.library.collectionState"
}

enum AppLanguageOption: String, CaseIterable, Identifiable {
    case english
    case vietnamese

    var id: Self { self }

    var titleKey: LocalizedStringKey {
        switch self {
        case .english:
            return "English"
        case .vietnamese:
            return "Vietnamese"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .english:
            return "en"
        case .vietnamese:
            return "vi"
        }
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    static var current: AppLanguageOption {
        guard
            let storedValue = UserDefaults.standard.string(forKey: AppSettingsKey.preferredLanguage),
            let language = AppLanguageOption(rawValue: storedValue)
        else {
            return .english
        }

        return language
    }
}

enum ReaderDarkModeOption: String, CaseIterable, Identifiable {
    case auto
    case off
    case on

    var id: Self { self }

    var titleKey: LocalizedStringKey {
        switch self {
        case .auto:
            return "Auto"
        case .off:
            return "Off"
        case .on:
            return "On"
        }
    }

    func usesDarkTheme(systemScheme: ColorScheme) -> Bool {
        switch self {
        case .auto:
            return systemScheme == .dark
        case .off:
            return false
        case .on:
            return true
        }
    }
}

enum LibraryHistorySortOption: String, CaseIterable, Identifiable {
    case newestChapter = "Chương mới"
    case lastRead = "Mới đọc"
    case title = "Tên truyện"

    var id: Self { self }

    var titleKey: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    var accessibilityID: String {
        switch self {
        case .newestChapter:
            return "newest_chapter"
        case .lastRead:
            return "last_read"
        case .title:
            return "title"
        }
    }
}

enum LibraryBookmarkSortOption: String, CaseIterable, Identifiable {
    case newestChapter = "Chương mới"
    case newestSaved = "Mới lưu"
    case title = "Tên truyện"

    var id: Self { self }

    var titleKey: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    var accessibilityID: String {
        switch self {
        case .newestChapter:
            return "newest_chapter"
        case .newestSaved:
            return "newest_saved"
        case .title:
            return "title"
        }
    }
}
