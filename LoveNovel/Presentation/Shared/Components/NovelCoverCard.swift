import SwiftUI
import LoveNovelCore
import LoveNovelDomain

struct NovelCoverCard: View {
    enum Variant: Sendable {
        case hero
        case compact
    }

    let book: Book
    let width: CGFloat
    let height: CGFloat
    var cornerRadius: CGFloat = 12
    var variant: Variant = .compact
    var showsBorder: Bool = false
    var shadowColor: Color = AppTheme.Colors.cardShadow
    var shadowRadius: CGFloat = 5
    var shadowYOffset: CGFloat = 2

    var body: some View {
        ZStack {
            coverSurface
            readabilityOverlay
        }
        .frame(width: width, height: height)
        .clipShape(.rect(cornerRadius: cornerRadius))
        .overlay {
            if showsBorder {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
        }
        .shadow(color: shadowColor, radius: shadowRadius, y: shadowYOffset)
        .overlay(alignment: .bottomLeading) {
            overlayContent
                .padding(contentPadding)
        }
    }

    @ViewBuilder
    private var coverSurface: some View {
        if let uiImage = UIImage(named: "cover.\(book.id)") {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [
                    Color(hex: book.accentHex),
                    Color(hex: book.accentHex).opacity(0.4),
                    Color.black.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var readabilityOverlay: some View {
        LinearGradient(
            colors: [
                .clear,
                Color.black.opacity(0.12),
                Color.black.opacity(0.35)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch variant {
        case .hero:
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text("A novel about the digital underground")
                    .font(.system(size: 6.5, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)

                Text(book.author)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }

        case .compact:
            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(book.author)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
        }
    }

    private var contentPadding: CGFloat {
        switch variant {
        case .hero:
            return 8
        case .compact:
            return 7
        }
    }
}
