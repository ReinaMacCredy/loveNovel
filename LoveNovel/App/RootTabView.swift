import SwiftUI

enum AppTab: Hashable {
    case library
    case explore
    case profile
}

struct RootTabView: View {
    private let container: AppContainer

    @State private var selectedTab: AppTab = .explore

    init(container: AppContainer = .live) {
        self.container = container
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView(container: container)
                .tag(AppTab.library)
                .tabItem {
                    Label("Library", systemImage: "chart.bar.fill")
                }

            ExploreView(container: container)
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
    }
}

#Preview {
    RootTabView(container: .live)
        .environmentObject(LibraryCollectionStore(storageKey: "RootTabView.preview.collection"))
}
