import SwiftUI

struct ExploreStoryModeSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedMode: ExploreViewModel.StoryMode

    @State private var draftMode: ExploreViewModel.StoryMode

    init(
        isPresented: Binding<Bool>,
        selectedMode: Binding<ExploreViewModel.StoryMode>
    ) {
        _isPresented = isPresented
        _selectedMode = selectedMode
        _draftMode = State(initialValue: selectedMode.wrappedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tùy chọn chế độ đọc")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, 32)
                .padding(.top, 22)
                .padding(.bottom, 10)

            ForEach(Array(ExploreViewModel.StoryMode.allCases.enumerated()), id: \.element.id) { index, mode in
                Button {
                    draftMode = mode
                } label: {
                    HStack(spacing: 12) {
                        Text(mode.optionTitle)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                        Spacer(minLength: 0)

                        StoryModeSelectionIndicator(isSelected: draftMode == mode)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("explore.story_mode.option.\(mode.id)")

                if index < ExploreViewModel.StoryMode.allCases.count - 1 {
                    Divider()
                        .overlay(AppTheme.Colors.detailDivider)
                }
            }

            Spacer(minLength: 8)

            Button {
                selectedMode = draftMode
                isPresented = false
            } label: {
                Text("Gửi")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
            .accessibilityIdentifier("explore.story_mode.submit")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 330, alignment: .topLeading)
        .background(AppTheme.Colors.screenBackground)
        .overlay(alignment: .top) {
            Divider()
                .overlay(AppTheme.Colors.detailDivider)
        }
        .accessibilityIdentifier("explore.story_mode.sheet")
    }
}

private struct StoryModeSelectionIndicator: View {
    let isSelected: Bool

    var body: some View {
        Group {
            if isSelected {
                Circle()
                    .fill(Color.black)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
            } else {
                Circle()
                    .stroke(Color.black.opacity(0.2), lineWidth: 2)
            }
        }
        .frame(width: 34, height: 34)
    }
}
