import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var showSortSettings: Bool = false

    var body: some View {
        ZStack {
            AppTheme.Colors.screenBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                header
                segmentControl

                Spacer()

                VStack(spacing: 18) {
                    Image(systemName: "folder")
                        .font(.system(size: 96, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.65))

                    VStack(spacing: 6) {
                        Text(viewModel.emptyLineOne)
                        Text(viewModel.emptyLineTwo)
                    }
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .padding(.top, 24)
            .padding(.bottom, 36)
        }
        .fullScreenCover(isPresented: $showSortSettings) {
            LibrarySortSettingsView()
        }
        .accessibilityIdentifier("screen.library")
    }

    private var header: some View {
        HStack {
            Text("Library")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Spacer()

            HStack(spacing: 18) {
                Button {
                    // Placeholder action for v1.
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .accessibilityIdentifier("library.header.search")
                .accessibilityLabel(Text("Library search"))

                Button {
                    showSortSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .accessibilityIdentifier("library.header.sort_settings")
                .accessibilityLabel(Text("Library sort settings"))
            }
            .buttonStyle(.plain)
        }
    }

    private var segmentControl: some View {
        HStack(spacing: 42) {
            ForEach(LibraryViewModel.Segment.allCases) { segment in
                Button {
                    viewModel.selectedSegment = segment
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(segment.titleKey)
                            .font(.system(size: 17, weight: viewModel.selectedSegment == segment ? .semibold : .regular))
                            .foregroundStyle(viewModel.selectedSegment == segment ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)

                        Capsule()
                            .fill(viewModel.selectedSegment == segment ? AppTheme.Colors.textSecondary : .clear)
                            .frame(height: 5)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    LibraryView()
}
