import SwiftUI

public enum AppSettingsKey {
    public static let preferredLanguage = "settings.preferredLanguage"
    public static let readerDarkMode = "settings.reader.darkMode"
    public static let readerLightTheme = "settings.reader.lightTheme"
    public static let readerDarkTheme = "settings.reader.darkTheme"
    public static let libraryHistorySort = "settings.library.historySort"
    public static let libraryBookmarkSort = "settings.library.bookmarkSort"
    public static let libraryCollectionState = "settings.library.collectionState"
}

public enum AppLanguageOption: String, CaseIterable, Identifiable {
    case english
    case vietnamese

    public var id: Self { self }

    public var titleKey: LocalizedStringKey {
        switch self {
        case .english:
            return "English"
        case .vietnamese:
            return "Vietnamese"
        }
    }

    public var localeIdentifier: String {
        switch self {
        case .english:
            return "en"
        case .vietnamese:
            return "vi"
        }
    }

    public var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    public static var current: AppLanguageOption {
        guard
            let storedValue = UserDefaults.standard.string(forKey: AppSettingsKey.preferredLanguage),
            let language = AppLanguageOption(rawValue: storedValue)
        else {
            return .english
        }

        return language
    }
}

public enum ReaderDarkModeOption: String, CaseIterable, Identifiable {
    case auto
    case off
    case on

    public var id: Self { self }

    public var titleKey: LocalizedStringKey {
        switch self {
        case .auto:
            return "Auto"
        case .off:
            return "Off"
        case .on:
            return "On"
        }
    }

    public func usesDarkTheme(systemScheme: ColorScheme) -> Bool {
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

public enum LibraryHistorySortOption: String, CaseIterable, Identifiable, Sendable {
    case newestChapter = "newest_chapter"
    case lastRead = "last_read"
    case title = "title"

    public static let defaultOption: Self = .lastRead

    public var id: Self { self }

    public var titleKey: LocalizedStringKey {
        LocalizedStringKey(localizationKey)
    }

    public var storageValue: String {
        rawValue
    }

    public var localizationKey: String {
        switch self {
        case .newestChapter:
            return "library.sort.option.newest_chapter"
        case .lastRead:
            return "library.sort.option.recently_read"
        case .title:
            return "library.sort.option.title"
        }
    }

    public var accessibilityID: String {
        switch self {
        case .newestChapter:
            return "newest_chapter"
        case .lastRead:
            return "last_read"
        case .title:
            return "title"
        }
    }

    public static func fromStorageValue(_ storageValue: String) -> Self? {
        if let option = Self(rawValue: storageValue) {
            return option
        }

        switch storageValue {
        case "Chương mới":
            return .newestChapter
        case "Mới đọc":
            return .lastRead
        case "Tên truyện":
            return .title
        default:
            return nil
        }
    }
}

public enum LibraryBookmarkSortOption: String, CaseIterable, Identifiable, Sendable {
    case newestChapter = "newest_chapter"
    case newestSaved = "newest_saved"
    case title = "title"

    public static let defaultOption: Self = .newestSaved

    public var id: Self { self }

    public var titleKey: LocalizedStringKey {
        LocalizedStringKey(localizationKey)
    }

    public var storageValue: String {
        rawValue
    }

    public var localizationKey: String {
        switch self {
        case .newestChapter:
            return "library.sort.option.newest_chapter"
        case .newestSaved:
            return "library.sort.option.recently_saved"
        case .title:
            return "library.sort.option.title"
        }
    }

    public var accessibilityID: String {
        switch self {
        case .newestChapter:
            return "newest_chapter"
        case .newestSaved:
            return "newest_saved"
        case .title:
            return "title"
        }
    }

    public static func fromStorageValue(_ storageValue: String) -> Self? {
        if let option = Self(rawValue: storageValue) {
            return option
        }

        switch storageValue {
        case "Chương mới":
            return .newestChapter
        case "Mới lưu":
            return .newestSaved
        case "Tên truyện":
            return .title
        default:
            return nil
        }
    }
}
