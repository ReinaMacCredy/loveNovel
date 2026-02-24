import SwiftUI
import LoveNovelCore
import LoveNovelDomain

struct DarkModeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettingsKey.readerDarkMode) private var readerDarkModeRawValue: String = ReaderDarkModeOption.auto.rawValue
    @AppStorage(AppSettingsKey.readerLightTheme) private var readerLightThemeRawValue: String = ReaderViewModel.ReaderThemeStyle.light.rawValue
    @AppStorage(AppSettingsKey.readerDarkTheme) private var readerDarkThemeRawValue: String = ReaderViewModel.ReaderThemeStyle.charcoal.rawValue

    var body: some View {
        ZStack {
            AppTheme.Colors.screenBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header(titleKey: "Dark mode")

                Divider()

                modeRow
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Light reading theme")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    themeRow(
                        prefix: "light_theme",
                        selectedTheme: selectedLightTheme,
                        onSelect: { theme in
                            readerLightThemeRawValue = theme.rawValue
                        }
                    )

                    Text("Dark reading theme")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .padding(.top, 6)

                    themeRow(
                        prefix: "dark_theme",
                        selectedTheme: selectedDarkTheme,
                        onSelect: { theme in
                            readerDarkThemeRawValue = theme.rawValue
                        }
                    )
                }
                .padding(.horizontal, AppTheme.Layout.horizontalInset)
                .padding(.top, 30)

                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen.settings.dark_mode")
    }

    private var modeRow: some View {
        HStack(spacing: 12) {
            Text("Mode")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer(minLength: 10)

            HStack(spacing: 0) {
                ForEach(ReaderDarkModeOption.allCases) { option in
                    Button {
                        readerDarkModeRawValue = option.rawValue
                    } label: {
                        Text(option.titleKey)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(selectedMode == option ? .white : AppTheme.Colors.accentBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(selectedMode == option ? AppTheme.Colors.accentBlue : .clear)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.dark_mode.mode.\(option.rawValue)")
                }
            }
            .frame(width: 220, height: 40)
            .overlay(
                Capsule()
                    .stroke(AppTheme.Colors.accentBlue.opacity(0.8), lineWidth: 1.1)
            )
            .clipShape(.capsule)
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
    }

    private var selectedMode: ReaderDarkModeOption {
        ReaderDarkModeOption(rawValue: readerDarkModeRawValue) ?? .auto
    }

    private var selectedLightTheme: ReaderViewModel.ReaderThemeStyle {
        ReaderViewModel.ReaderThemeStyle(rawValue: readerLightThemeRawValue) ?? .light
    }

    private var selectedDarkTheme: ReaderViewModel.ReaderThemeStyle {
        ReaderViewModel.ReaderThemeStyle(rawValue: readerDarkThemeRawValue) ?? .charcoal
    }

    private func themeRow(
        prefix: String,
        selectedTheme: ReaderViewModel.ReaderThemeStyle,
        onSelect: @escaping (ReaderViewModel.ReaderThemeStyle) -> Void
    ) -> some View {
        HStack(spacing: 12) {
            ForEach(ReaderViewModel.ReaderThemeStyle.allCases) { theme in
                Button {
                    onSelect(theme)
                } label: {
                    ZStack {
                        Circle()
                            .fill(themeColor(for: theme))
                            .frame(width: 36, height: 36)

                        Circle()
                            .stroke(AppTheme.Colors.detailDivider, lineWidth: 0.5)
                            .frame(width: 36, height: 36)

                        if selectedTheme == theme {
                            Circle()
                                .stroke(AppTheme.Colors.accentBlue, lineWidth: 3)
                                .frame(width: 36, height: 36)

                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(theme == .charcoal || theme == .black ? .white : AppTheme.Colors.accentBlue)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.dark_mode.\(prefix).\(theme.rawValue)")
            }
        }
    }

    private func themeColor(for theme: ReaderViewModel.ReaderThemeStyle) -> Color {
        switch theme {
        case .light:
            return Color(red: 0.96, green: 0.97, blue: 0.98)
        case .coolGray:
            return Color(red: 0.90, green: 0.91, blue: 0.94)
        case .pink:
            return Color(red: 0.90, green: 0.86, blue: 0.86)
        case .ivory:
            return Color(red: 0.90, green: 0.89, blue: 0.83)
        case .sepia:
            return Color(red: 0.72, green: 0.68, blue: 0.60)
        case .warmGray:
            return Color(red: 0.71, green: 0.67, blue: 0.65)
        case .charcoal:
            return Color(red: 0.16, green: 0.16, blue: 0.19)
        case .black:
            return .black
        }
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
            .accessibilityIdentifier("settings.dark_mode.back")

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
        DarkModeSettingsView()
    }
}
