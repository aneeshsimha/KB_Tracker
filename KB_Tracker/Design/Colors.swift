// Colors.swift
// KB_Tracker
//
// Design system color definitions

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

struct AppColors {
    static let background = Color(hex: "#050505")      // Near-black
    static let surface = Color(hex: "#111111")         // Cards, elevated surfaces
    static let border = Color(hex: "#222222")          // Subtle borders
    static let textPrimary = Color.white               // Main text
    static let textSecondary = Color(hex: "#666666")   // Secondary/muted text
    static let accent = Color.white                    // Buttons, highlights
    static let warning = Color(hex: "#FF3B30")         // Overtime indicator
}
