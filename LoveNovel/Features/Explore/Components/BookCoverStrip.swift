import SwiftUI

enum BookCoverSize {
    case compact
    case regular

    var width: CGFloat {
        switch self {
        case .compact:
            return 56
        case .regular:
            return 118
        }
    }

    var height: CGFloat {
        switch self {
        case .compact:
            return 56
        case .regular:
            return 168
        }
    }
}

struct BookCoverStrip: View {
    let books: [Book]
    let size: BookCoverSize
    let showTitle: Bool
    let onTapBook: (Book) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Layout.cardSpacing) {
                ForEach(books) { book in
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            onTapBook(book)
                        } label: {
                            BookCoverCard(book: book, size: size)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("book.cover.\(book.id)")
                        .accessibilityLabel(book.title)
                        .accessibilityHint("Open story details")

                        if showTitle {
                            Text(book.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                        }
                    }
                }
            }
        }
        .scrollClipDisabled()
    }
}

private struct BookCoverCard: View {
    let book: Book
    let size: BookCoverSize

    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.Layout.coverCornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: book.accentHex),
                        Color(hex: book.accentHex).opacity(0.4),
                        Color.black.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size.width, height: size.height)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.system(size: size == .compact ? 10 : 13, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if size == .regular {
                        Text(book.author)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                }
                .padding(8)
            }
            .shadow(color: AppTheme.Colors.cardShadow, radius: 4, y: 2)
    }
}
