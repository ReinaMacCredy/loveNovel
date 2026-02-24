import SwiftUI
import LoveNovelCore
import LoveNovelDomain

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.Colors.screenBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Settings")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Spacer()

                    Color.clear
                        .frame(width: 28, height: 28)
                }
                .padding(.horizontal, AppTheme.Layout.horizontalInset)
                .padding(.top, 20)
                .padding(.bottom, 14)

                Divider()

                NavigationLink {
                    LanguageSettingsView()
                } label: {
                    settingsRow(
                        titleKey: "Languages",
                        accessibilityIdentifier: "settings.row.languages"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.row.languages")

                Divider()

                NavigationLink {
                    DarkModeSettingsView()
                } label: {
                    settingsRow(
                        titleKey: "Dark mode",
                        accessibilityIdentifier: "settings.row.dark_mode"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.row.dark_mode")

                Divider()

                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen.settings")
    }

    private func settingsRow(titleKey: String, accessibilityIdentifier: String) -> some View {
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
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
