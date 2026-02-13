import SwiftUI

struct LibrarySortSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppSettingsKey.libraryHistorySort) private var historySortRawValue: String = LibraryHistorySortOption.lastRead.rawValue
    @AppStorage(AppSettingsKey.libraryBookmarkSort) private var bookmarkSortRawValue: String = LibraryBookmarkSortOption.newestSaved.rawValue

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
            .accessibilityIdentifier("library.sort.back")
            .accessibilityLabel(Text("Library sort back"))

            Spacer()

            Text("Sắp xếp tủ truyện")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var historySort: LibraryHistorySortOption {
        LibraryHistorySortOption(rawValue: historySortRawValue) ?? .lastRead
    }

    private var bookmarkSort: LibraryBookmarkSortOption {
        LibraryBookmarkSortOption(rawValue: bookmarkSortRawValue) ?? .newestSaved
    }

    private var historyRow: some View {
        sortRow(titleKey: "Lịch sử") {
            HStack(spacing: 0) {
                ForEach(LibraryHistorySortOption.allCases) { option in
                    Button {
                        historySortRawValue = option.rawValue
                    } label: {
                        Text(option.titleKey)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(historySort == option ? .white : AppTheme.Colors.accentBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(historySort == option ? AppTheme.Colors.accentBlue : .clear)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("library.sort.history.\(option.accessibilityID)")
                }
            }
            .frame(width: 228, height: 40)
            .overlay {
                Capsule()
                    .stroke(AppTheme.Colors.accentBlue.opacity(0.8), lineWidth: 1.1)
            }
            .clipShape(Capsule())
        }
    }

    private var bookmarkRow: some View {
        sortRow(titleKey: "Đánh dấu") {
            HStack(spacing: 0) {
                ForEach(LibraryBookmarkSortOption.allCases) { option in
                    Button {
                        bookmarkSortRawValue = option.rawValue
                    } label: {
                        Text(option.titleKey)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(bookmarkSort == option ? .white : AppTheme.Colors.accentBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(bookmarkSort == option ? AppTheme.Colors.accentBlue : .clear)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("library.sort.bookmark.\(option.accessibilityID)")
                }
            }
            .frame(width: 228, height: 40)
            .overlay {
                Capsule()
                    .stroke(AppTheme.Colors.accentBlue.opacity(0.8), lineWidth: 1.1)
            }
            .clipShape(Capsule())
        }
    }

    private func sortRow<Control: View>(titleKey: String, @ViewBuilder control: () -> Control) -> some View {
        HStack(spacing: 12) {
            Text(LocalizedStringKey(titleKey))
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
