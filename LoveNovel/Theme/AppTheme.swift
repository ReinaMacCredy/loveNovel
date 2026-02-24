import SwiftUI
import UIKit

public enum AppTheme {
    public enum Colors {
        public static let screenBackground = Color(uiColor: .systemGroupedBackground)
        public static let surfaceBackground = Color(uiColor: .secondarySystemGroupedBackground)
        public static let elevatedSurfaceBackground = Color(uiColor: .tertiarySystemGroupedBackground)
        public static let translucentSurfaceBackground = Color(uiColor: .systemBackground).opacity(0.84)
        public static let textPrimary = Color(uiColor: .label)
        public static let textSecondary = Color(uiColor: .secondaryLabel)
        public static let cardShadow = Color.black.opacity(0.12)
        public static let accentBlue = Color(red: 0.16, green: 0.44, blue: 0.64)
        public static let tabActive = Color(uiColor: .label)
        public static let star = Color(red: 0.98, green: 0.75, blue: 0.14)
        public static let heroOverlay = Color.black.opacity(0.34)
        public static let detailDivider = Color(uiColor: .separator).opacity(0.55)
        public static let pillBorder = Color(red: 0.16, green: 0.44, blue: 0.64)
        public static let mutedIcon = Color(uiColor: .tertiaryLabel)
        public static let readerBackground = Color(uiColor: .systemBackground)
        public static let emphasizedSurface = Color(uiColor: .label)
        public static let emphasizedText = Color(uiColor: .systemBackground)
    }

    public enum Layout {
        public static let horizontalInset: CGFloat = 16
        public static let sectionSpacing: CGFloat = 24
        public static let cardSpacing: CGFloat = 10
        public static let coverCornerRadius: CGFloat = 16
        public static let featuredCornerRadius: CGFloat = 22
        public static let detailHeroHeight: CGFloat = 246
        public static let detailTabHeight: CGFloat = 68
        public static let detailSectionSpacing: CGFloat = 18
        public static let detailBottomInset: CGFloat = 10
        public static let detailActionBarCornerRadius: CGFloat = 22
    }
}

public extension Color {
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
