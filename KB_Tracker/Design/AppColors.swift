// AppColors.swift
// KB_Tracker
//
// Design system color definitions

import SwiftUI

extension Color {
    /// Initialize a Color from a 6-digit hex string
    /// - Parameter hex: Hex color string (e.g., "#FF0000" or "FF0000")
    init(hex: String) {
        let int = UInt64(hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted), radix: 16) ?? 0
        self.init(
            .sRGB,
            red: Double(int >> 16 & 0xFF) / 255,
            green: Double(int >> 8 & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255
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
    static let redDim = red.opacity(0.22)
    /// Green — completion success
    static let green = Color(hex: "#30D158")
    /// Overtime background tint (#0a0202)
    static let overtimeBackground = Color(hex: "#0a0202")
}
