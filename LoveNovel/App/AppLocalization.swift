import Foundation

public enum AppLocalization {
    private final class BundleToken {}
    private static let preferredBundleIdentifiers = [
        "com.reinamaccredy.LoveNovelCore",
        "com.reinamaccredy.lovenovelcore"
    ]
    private static let candidateBundleList = candidateBundles()
    private static let localizedBundlesByLanguage: [String: Bundle] = {
        Dictionary(
            uniqueKeysWithValues: AppLanguageOption.allCases.compactMap { language in
                guard let localizedBundle = candidateBundleList
                    .lazy
                    .compactMap({ localizationBundle(in: $0, language: language) })
                    .first
                else {
                    return nil
                }

                return (language.localeIdentifier, localizedBundle)
            }
        )
    }()

    public static func string(_ key: String, language: AppLanguageOption = .current) -> String {
        localizedBundle(for: language).localizedString(forKey: key, value: key, table: nil)
    }

    public static func format(
        _ key: String,
        language: AppLanguageOption = .current,
        _ arguments: CVarArg...
    ) -> String {
        let format = string(key, language: language)
        return String(format: format, locale: language.locale, arguments: arguments)
    }

    private static func localizedBundle(for language: AppLanguageOption) -> Bundle {
        localizedBundlesByLanguage[language.localeIdentifier] ?? Bundle(for: BundleToken.self)
    }

    private static func candidateBundles() -> [Bundle] {
        var candidates = preferredBundleIdentifiers.compactMap(Bundle.init(identifier:))
        let tokenBundle = Bundle(for: BundleToken.self)
        candidates.append(tokenBundle)
        candidates.append(Bundle.main)

        for rootURL in [
            tokenBundle.privateFrameworksURL,
            Bundle.main.privateFrameworksURL,
            tokenBundle.builtInPlugInsURL?.appendingPathComponent("Frameworks")
        ].compactMap({ $0 }) {
            let coreFrameworkURL = rootURL.appendingPathComponent("LoveNovelCore.framework")
            if let coreBundle = Bundle(url: coreFrameworkURL) {
                candidates.append(coreBundle)
            }
        }

        var seenBundlePaths = Set<String>()
        return candidates.filter { seenBundlePaths.insert($0.bundlePath).inserted }
    }

    private static func localizationBundle(
        in candidate: Bundle,
        language: AppLanguageOption
    ) -> Bundle? {
        if let localizedVariant = localizedVariantBundle(in: candidate, language: language) {
            return localizedVariant
        }

        guard let nestedBundleURLs = candidate.urls(forResourcesWithExtension: "bundle", subdirectory: nil)
        else {
            return nil
        }

        for nestedBundleURL in nestedBundleURLs {
            guard let nestedBundle = Bundle(url: nestedBundleURL) else {
                continue
            }

            if let localizedVariant = localizedVariantBundle(in: nestedBundle, language: language) {
                return localizedVariant
            }
        }

        return nil
    }

    private static func localizedVariantBundle(
        in candidate: Bundle,
        language: AppLanguageOption
    ) -> Bundle? {
        guard let path = candidate.path(forResource: language.localeIdentifier, ofType: "lproj") else {
            return nil
        }

        return Bundle(path: path)
    }
}
