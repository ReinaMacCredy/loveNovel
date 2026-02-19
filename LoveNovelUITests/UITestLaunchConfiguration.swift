import XCTest

enum UITestLaunchConfiguration {
    enum Timeout {
        static let brief: TimeInterval = 1
        static let tutorial: TimeInterval = 1.5
        static let short: TimeInterval = 2
        static let sheet: TimeInterval = 3
        static let medium: TimeInterval = 4
        static let list: TimeInterval = 6
        static let long: TimeInterval = 8
        static let longest: TimeInterval = 10
    }

    static func launchConfiguredApp() -> XCUIApplication {
        let app = XCUIApplication()
        apply(to: app)
        app.launch()
        return app
    }

    static func apply(to app: XCUIApplication) {
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-settings.preferredLanguage", "english",
            "-settings.readerDarkMode", "auto",
            "-settings.readerLightTheme", "light",
            "-settings.readerDarkTheme", "charcoal",
            "-reader.didShowTutorial", "1"
        ]
    }
}
