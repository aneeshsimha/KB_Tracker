// AppColors.swift
// KB_Tracker
//
// Design system color definitions

import SwiftUI

extension Color {
    /// Initialize a Color from a hex string
    /// - Parameter hex: Hex color string (e.g., "#FF0000" or "FF0000")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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

struct AppColors {
    // MARK: - Surfaces (from theme.jsx palette)

    /// App background — near-black
    static let background = Color(hex: "#050505")
    /// Base elevated surface for cards
    static let surface = Color(hex: "#0e0e0e")
    /// Second elevation (inset tiles, menus)
    static let surface2 = Color(hex: "#161616")
    /// Third elevation (active steppers, pressed states)
    static let surface3 = Color(hex: "#1f1f1f")
    /// Hairline border (≈ rgba(255,255,255,0.08))
    static let hairline = Color.white.opacity(0.08)
    /// Stronger hairline (≈ rgba(255,255,255,0.14))
    static let hairline2 = Color.white.opacity(0.14)

    // MARK: - Text / ink tiers

    /// Primary ink (white)
    static let ink = Color.white
    /// 72% ink — secondary text
    static let ink2 = Color.white.opacity(0.72)
    /// 50% ink — tertiary / eyebrow
    static let ink3 = Color.white.opacity(0.50)
    /// 32% ink — quaternary / disabled
    static let ink4 = Color.white.opacity(0.32)

    // MARK: - Accents

    /// Red — warnings, overtime, destructive
    static let red = Color(hex: "#FF3B30")
    /// Dimmed red glow (≈ rgba(255,59,48,0.22))
    static let redDim = Color(red: 1.0, green: 59.0/255.0, blue: 48.0/255.0).opacity(0.22)
    /// Green — completion success
    static let green = Color(hex: "#30D158")
    /// Overtime background tint (#0a0202)
    static let overtimeBackground = Color(hex: "#0a0202")

    // MARK: - Legacy aliases (kept so pre-overhaul views still compile;
    // remove during cleanup once all views use the tiers above)
    static let border = hairline
    static let textPrimary = ink
    static let textSecondary = ink3
    static let accent = ink
    static let warning = red
}
