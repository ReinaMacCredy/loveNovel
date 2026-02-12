import SwiftUI

enum AppTheme {
    enum Colors {
        static let screenBackground = Color(red: 0.95, green: 0.95, blue: 0.96)
        static let textPrimary = Color.black.opacity(0.9)
        static let textSecondary = Color.black.opacity(0.45)
        static let cardShadow = Color.black.opacity(0.07)
        static let accentBlue = Color(red: 0.16, green: 0.44, blue: 0.64)
        static let tabActive = Color.black
        static let star = Color(red: 0.98, green: 0.75, blue: 0.14)
    }

    enum Layout {
        static let horizontalInset: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let cardSpacing: CGFloat = 10
        static let coverCornerRadius: CGFloat = 16
        static let featuredCornerRadius: CGFloat = 22
    }
}

extension Color {
    init(hex: String, fallback: Color = .gray) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var hexValue: UInt64 = 0

        guard Scanner(string: sanitized).scanHexInt64(&hexValue) else {
            self = fallback
            return
        }

        let a, r, g, b: UInt64
        switch sanitized.count {
        case 3:
            (a, r, g, b) = (
                255,
                (hexValue >> 8) * 17,
                (hexValue >> 4 & 0xF) * 17,
                (hexValue & 0xF) * 17
            )
        case 6:
            (a, r, g, b) = (
                255,
                hexValue >> 16,
                hexValue >> 8 & 0xFF,
                hexValue & 0xFF
            )
        case 8:
            (a, r, g, b) = (
                hexValue >> 24,
                hexValue >> 16 & 0xFF,
                hexValue >> 8 & 0xFF,
                hexValue & 0xFF
            )
        default:
            self = fallback
            return
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
