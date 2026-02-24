import SwiftUI
import LoveNovelCore
import LoveNovelDomain

struct ProfileView: View {
    @State private var showLoginAlert: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.screenBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    Text("Profile")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .padding(.horizontal, AppTheme.Layout.horizontalInset)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                    Divider()

                    NavigationLink {
                        SettingsView()
                    } label: {
                        menuRow(
                            titleKey: "Settings",
                            accessibilityIdentifier: "profile.row.settings"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("profile.row.settings")

                    Divider()

                    Button {
                        showLoginAlert = true
                    } label: {
                        menuRow(
                            titleKey: "Login",
                            accessibilityIdentifier: "profile.row.login"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()

                    Spacer()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Coming Soon", isPresented: $showLoginAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Login screen is planned for v2.")
            }
            .accessibilityIdentifier("screen.profile")
        }
    }

    private func menuRow(titleKey: String, accessibilityIdentifier: String) -> some View {
        HStack {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#Preview {
    ProfileView()
}
