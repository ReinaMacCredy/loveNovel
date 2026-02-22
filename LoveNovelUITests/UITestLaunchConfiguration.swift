import XCTest

enum UITestLaunchConfiguration {
    enum Timeout {
        static let brief: TimeInterval = 1.5
        static let tutorial: TimeInterval = 2.5
        static let short: TimeInterval = 3
        static let sheet: TimeInterval = 5
        static let medium: TimeInterval = 6
        static let list: TimeInterval = 8
        static let long: TimeInterval = 10
        static let longest: TimeInterval = 12
    }

    static func launchConfiguredApp(seedLibrary: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        apply(to: app, seedLibrary: seedLibrary)
        app.launch()
        return app
    }

    static func apply(to app: XCUIApplication, seedLibrary: Bool = false) {
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-uitest.resetLibrary",
            "-settings.preferredLanguage", "english",
            "-settings.readerDarkMode", "auto",
            "-settings.readerLightTheme", "light",
            "-settings.readerDarkTheme", "charcoal",
            "-reader.didShowTutorial", "1"
        ]

        if seedLibrary {
            app.launchArguments += ["-uitest.seedLibrary"]
        }
    }
}
