import SwiftUI

enum AppTab: Hashable {
    case library
    case explore
    case profile
}

struct RootTabView: View {
    @State private var selectedTab: AppTab = .explore

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tag(AppTab.library)
                .tabItem {
                    Label("Library", systemImage: "chart.bar.fill")
                }

            ExploreView()
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
    RootTabView()
}
