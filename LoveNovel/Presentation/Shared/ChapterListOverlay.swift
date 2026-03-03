import SwiftUI
import LoveNovelCore
import LoveNovelDomain

struct ChapterListOverlay: View {
    let chapters: [BookChapter]
    let currentChapterIndex: Int
    let titleKey: LocalizedStringKey
    let accessibilityPrefix: String
    let onBack: () -> Void
    let onReload: (() -> Void)?
    let onSelectChapter: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.Colors.screenBackground.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("\(accessibilityPrefix).chapter_list.back")

            Spacer()

            if let onReload {
                Button(action: onReload) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(accessibilityPrefix).chapter_list.reload")
            }
        }
        .overlay {
            Text(titleKey)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, AppTheme.Layout.horizontalInset)
        .safeAreaPadding(.top, 8)
        .padding(.bottom, 8)
    }

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(chapters) { chapter in
                        row(for: chapter)
                            .id(chapter.index)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                proxy.scrollTo(currentChapterIndex, anchor: .center)
            }
        }
    }

    private func row(for chapter: BookChapter) -> some View {
        let isCurrentChapter = chapter.index == currentChapterIndex

        return Button {
            onSelectChapter(chapter.index)
        } label: {
            HStack(alignment: .top, spacing: 16) {
                Text("\(chapter.index)")
                    .font(.system(size: 15, weight: isCurrentChapter ? .medium : .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(width: 34, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(chapter.title)
                        .font(.system(size: 16, weight: isCurrentChapter ? .medium : .regular))
                        .foregroundStyle(
                            isCurrentChapter
                                ? AppTheme.Colors.textPrimary
                                : AppTheme.Colors.textSecondary
                        )
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text("(\(chapter.timestampText))")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.9))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, AppTheme.Layout.horizontalInset)
            .background(
                isCurrentChapter
                    ? AppTheme.Colors.textPrimary.opacity(0.06)
                    : .clear
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(accessibilityPrefix).chapter_list.row.\(chapter.index)")
    }
}
