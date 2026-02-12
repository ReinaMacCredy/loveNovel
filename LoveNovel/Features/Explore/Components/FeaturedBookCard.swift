import SwiftUI

struct FeaturedBookCard: View {
    let book: Book
    let onRead: (Book) -> Void
    let onAdd: (Book) -> Void
    let onTapPoster: (Book) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 14) {
                Text(book.title)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(book.summary)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                RatingView(rating: book.rating)

                HStack(spacing: 14) {
                    Button {
                        onRead(book)
                    } label: {
                        Text("Read")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(minWidth: 90)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.black))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onAdd(book)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 19, weight: .regular))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(AppTheme.Colors.accentBlue))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RoundedRectangle(cornerRadius: AppTheme.Layout.featuredCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: book.accentHex), Color.black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 166, height: 250)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(.white)
                        Text("A Novella")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(12)
                }
                .accessibilityIdentifier("book.featured.\(book.id)")
                .onTapGesture {
                    onTapPoster(book)
                }
        }
    }
}

private struct RatingView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: symbol(for: index))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.star)
            }

            Text(String(format: "%.1f", rating))
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(.leading, 12)
        }
    }

    private func symbol(for index: Int) -> String {
        let threshold = Double(index) + 1
        if rating >= threshold {
            return "star.fill"
        }

        if rating + 0.5 >= threshold {
            return "star.leadinghalf.filled"
        }

        return "star"
    }
}
