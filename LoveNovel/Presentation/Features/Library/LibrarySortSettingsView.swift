import SwiftUI
import LoveNovelCore
import LoveNovelDomain

struct LibrarySortSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppSettingsKey.libraryHistorySort) private var historySortRawValue: String = LibraryHistorySortOption.defaultOption.storageValue
    @AppStorage(AppSettingsKey.libraryBookmarkSort) private var bookmarkSortRawValue: String = LibraryBookmarkSortOption.defaultOption.storageValue

    var body: some View {
        ZStack {
            AppTheme.Colors.screenBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header

                VStack(alignment: .leading, spacing: 24) {
                    historyRow
                    bookmarkRow
                }
                .padding(.horizontal, AppTheme.Layout.horizontalInset)
                .padding(.top, 18)

                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .accessibilityIdentifier("screen.library.sort_settings")
    }

    private var header: some View {
        ZStack {
            Text("library.sort.title")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            HStack {
                backButton

                Spacer()

                resetButton
            }
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var historySort: LibraryHistorySortOption {
        LibraryHistorySortOption.fromStorageValue(historySortRawValue) ?? .defaultOption
    }

    private var bookmarkSort: LibraryBookmarkSortOption {
        LibraryBookmarkSortOption.fromStorageValue(bookmarkSortRawValue) ?? .defaultOption
    }

    private var usesDefaultSortSelection: Bool {
        historySort == .defaultOption && bookmarkSort == .defaultOption
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("library.sort.back")
        .accessibilityLabel(Text("library.sort.accessibility.back"))
    }

    private var resetButton: some View {
        Button {
            resetToDefaultSorts()
        } label: {
            Text("library.sort.action.reset")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accentBlue)
        }
        .buttonStyle(.plain)
        .disabled(usesDefaultSortSelection)
        .opacity(usesDefaultSortSelection ? 0.5 : 1)
        .accessibilityIdentifier("library.sort.reset")
        .accessibilityLabel(Text("library.sort.action.reset"))
    }

    private func resetToDefaultSorts() {
        historySortRawValue = LibraryHistorySortOption.defaultOption.storageValue
        bookmarkSortRawValue = LibraryBookmarkSortOption.defaultOption.storageValue
    }

    private var historyRow: some View {
        sortRow(titleKey: "library.sort.section.history") {
            HStack(spacing: 0) {
                ForEach(LibraryHistorySortOption.allCases) { option in
                    Button {
                        historySortRawValue = option.storageValue
                    } label: {
                        Text(option.titleKey)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(historySort == option ? .white : AppTheme.Colors.accentBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(historySort == option ? AppTheme.Colors.accentBlue : .clear)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(option.titleKey))
                    .accessibilityIdentifier("library.sort.history.\(option.accessibilityID)")
                    .accessibilityValue(
                        historySort == option
                            ? AppLocalization.string("selected")
                            : AppLocalization.string("unselected")
                    )
                }
            }
            .frame(width: 228, height: 40)
            .overlay {
                Capsule()
                    .stroke(AppTheme.Colors.accentBlue.opacity(0.8), lineWidth: 1.1)
            }
            .clipShape(.capsule)
        }
    }

    private var bookmarkRow: some View {
        sortRow(titleKey: "library.sort.section.bookmark") {
            HStack(spacing: 0) {
                ForEach(LibraryBookmarkSortOption.allCases) { option in
                    Button {
                        bookmarkSortRawValue = option.storageValue
                    } label: {
                        Text(option.titleKey)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(bookmarkSort == option ? .white : AppTheme.Colors.accentBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(bookmarkSort == option ? AppTheme.Colors.accentBlue : .clear)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(option.titleKey))
                    .accessibilityIdentifier("library.sort.bookmark.\(option.accessibilityID)")
                    .accessibilityValue(
                        bookmarkSort == option
                            ? AppLocalization.string("selected")
                            : AppLocalization.string("unselected")
                    )
                }
            }
            .frame(width: 228, height: 40)
            .overlay {
                Capsule()
                    .stroke(AppTheme.Colors.accentBlue.opacity(0.8), lineWidth: 1.1)
            }
            .clipShape(.capsule)
        }
    }

    private func sortRow<Control: View>(
        titleKey: LocalizedStringKey,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 12) {
            Text(titleKey)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Spacer(minLength: 6)

            control()
        }
    }
}

#Preview {
    NavigationStack {
        LibrarySortSettingsView()
    }
}
