import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettingsKey.preferredLanguage) private var preferredLanguageRawValue: String = AppLanguageOption.english.rawValue

    var body: some View {
        ZStack {
            AppTheme.Colors.screenBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header(titleKey: "Settings")

                Divider()

                HStack(spacing: 12) {
                    Text("Languages")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Spacer(minLength: 10)

                    HStack(spacing: 0) {
                        ForEach(AppLanguageOption.allCases) { option in
                            Button {
                                preferredLanguageRawValue = option.rawValue
                            } label: {
                                Text(option.titleKey)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(selectedLanguage == option ? .white : AppTheme.Colors.accentBlue)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(selectedLanguage == option ? AppTheme.Colors.accentBlue : .clear)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("settings.languages.option.\(option.rawValue)")
                        }
                    }
                    .frame(width: 180, height: 40)
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.Colors.accentBlue.opacity(0.8), lineWidth: 1.1)
                    )
                    .clipShape(.capsule)
                }
                .padding(.horizontal, AppTheme.Layout.horizontalInset)
                .padding(.top, 16)

                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen.settings.languages")
    }

    private var selectedLanguage: AppLanguageOption {
        AppLanguageOption(rawValue: preferredLanguageRawValue) ?? .english
    }

    private func header(titleKey: String) -> some View {
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
            .accessibilityIdentifier("settings.languages.back")

            Spacer()

            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
