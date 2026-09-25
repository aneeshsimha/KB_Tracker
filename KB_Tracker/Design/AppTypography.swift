// AppTypography.swift
// KB_Tracker
//
// Design system typography definitions

import SwiftUI

struct AppTypography {
    // MARK: - Design-system styles (match theme.jsx)
    // Mono == JetBrains Mono in the prototype; we use system .monospaced (SF Mono).

    /// Medium title (kb-title)
    static let titleMd = Font.system(size: 24, weight: .bold)
    /// Body copy (kb-body, 15pt)
    static let bodyText = Font.system(size: 15, weight: .regular)

    /// Giant timer numeral (kb-timer, 116pt mono)
    static let timerXL = Font.system(size: 116, weight: .bold, design: .monospaced)
    /// Big mono numeral used by Home dials and the rest countdown (72pt)
    static let numeral = Font.system(size: 72, weight: .bold, design: .monospaced)
    /// Detail-hero mono numeral (56pt)
    static let numeralLg = Font.system(size: 56, weight: .bold, design: .monospaced)
    /// Standalone mono helper for inline tabular figures
    static func mono(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced)
    }
}
