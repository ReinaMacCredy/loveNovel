import SwiftUI
import LoveNovelCore
import LoveNovelDomain

struct SectionHeader: View {
    let title: String
    let onTapChevron: () -> Void

    var body: some View {
        HStack {
            Text(LocalizedStringKey(title))
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            Button(action: onTapChevron) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            .buttonStyle(.plain)
        }
    }
}
