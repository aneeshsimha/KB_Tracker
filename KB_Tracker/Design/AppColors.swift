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
    // MARK: - Background Colors

    /// Warm near-black background
    static let background = Color(hex: "#0A0908")

    /// Dark espresso surface for cards and containers
    static let surface = Color(hex: "#161210")

    /// Warm border for separators and outlines
    static let border = Color(hex: "#2A2420")

    // MARK: - Text Colors

    /// Primary text color (warm cream)
    static let textPrimary = Color(hex: "#F5EDE4")

    /// Secondary/muted text color (warm gray)
    static let textSecondary = Color(hex: "#8A7D6F")

    // MARK: - Accent Colors

    /// Copper accent for buttons and highlights
    static let accent = Color(hex: "#D4845A")

    /// Darker copper for gradient endpoints
    static let accentDark = Color(hex: "#B06A42")

    /// Warning/overtime indicator color (warmer red)
    static let warning = Color(hex: "#E5503E")

    // MARK: - Gradients

    /// Subtle warm background gradient
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "#0A0908"), Color(hex: "#0F0C09")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Copper button gradient
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "#D4845A"), Color(hex: "#B06A42")],
        startPoint: .leading,
        endPoint: .trailing
    )
}
