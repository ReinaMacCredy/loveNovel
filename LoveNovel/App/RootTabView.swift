import SwiftUI
import LoveNovelCore

enum AppTab: Hashable {
    case library
    case explore
    case profile
}

public struct RootTabView: View {
    @AppStorage(AppSettingsKey.preferredLanguage) private var preferredLanguageRawValue: String = AppLanguageOption.english.rawValue
    @StateObject private var libraryStore = LibraryCollectionStore()
    private let featureFactory: any AppFeatureFactory

    @State private var selectedTab: AppTab = .explore

    public init() {
        self.featureFactory = AppContainer.live
    }

    init(featureFactory: any AppFeatureFactory) {
        self.featureFactory = featureFactory
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView(featureFactory: featureFactory)
                .tag(AppTab.library)
                .tabItem {
                    Label("Library", systemImage: "chart.bar.fill")
                }

            ExploreView(featureFactory: featureFactory)
                .tag(AppTab.explore)
                .tabItem {
                    Label("Explore", systemImage: "safari")
                }

            ProfileView()
                .tag(AppTab.profile)
                .tabItem {
                    Label("Profile", systemImage: "person.2.circle")
                }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(AppTheme.Colors.tabActive)
        .background {
            AppTheme.Colors.screenBackground
                .ignoresSafeArea()
        }
        .environmentObject(libraryStore)
        .environment(\.locale, selectedLanguage.locale)
    }

    private var selectedLanguage: AppLanguageOption {
        AppLanguageOption(rawValue: preferredLanguageRawValue) ?? .english
    }
}

#Preview {
    RootTabView(featureFactory: PreviewFeatureFactory.live)
}
