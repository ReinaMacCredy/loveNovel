import Foundation

enum AppLocalization {
    private final class BundleToken {}

    static func string(_ key: String, language: AppLanguageOption = .current) -> String {
        localizedBundle(for: language).localizedString(forKey: key, value: key, table: nil)
    }

    static func format(
        _ key: String,
        language: AppLanguageOption = .current,
        _ arguments: CVarArg...
    ) -> String {
        let format = string(key, language: language)
        return String(format: format, locale: language.locale, arguments: arguments)
    }

    private static func localizedBundle(for language: AppLanguageOption) -> Bundle {
        for candidate in [Bundle(for: BundleToken.self), Bundle.main] {
            guard let path = candidate.path(forResource: language.localeIdentifier, ofType: "lproj") else {
                continue
            }

            if let bundle = Bundle(path: path) {
                return bundle
            }
        }

        return Bundle(for: BundleToken.self)
    }
}
