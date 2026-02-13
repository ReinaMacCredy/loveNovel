import SwiftUI

enum AppSettingsKey {
    static let preferredLanguage = "settings.preferredLanguage"
    static let readerDarkMode = "settings.reader.darkMode"
    static let readerLightTheme = "settings.reader.lightTheme"
    static let readerDarkTheme = "settings.reader.darkTheme"
}

enum AppLanguageOption: String, CaseIterable, Identifiable {
    case english
    case vietnamese

    var id: Self { self }

    var title: String {
        switch self {
        case .english:
            return "English"
        case .vietnamese:
            return "Tiếng Việt"
        }
    }
}

enum ReaderDarkModeOption: String, CaseIterable, Identifiable {
    case auto
    case off
    case on

    var id: Self { self }

    var title: String {
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
