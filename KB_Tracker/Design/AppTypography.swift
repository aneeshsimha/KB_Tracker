// AppTypography.swift
// KB_Tracker
//
// Design system typography definitions

import SwiftUI

struct AppTypography {
    // MARK: - Design-system styles (match theme.jsx)
    // Mono == JetBrains Mono in the prototype; we use system .monospaced (SF Mono).

    /// Eyebrow label — mono 11pt, used uppercase with kerning (see `Eyebrow` view).
    static let eyebrow = Font.system(size: 11, weight: .medium, design: .monospaced)
    /// Large display title (kb-title-lg)
    static let titleLg = Font.system(size: 32, weight: .bold)
    /// Medium title (kb-title)
    static let titleMd = Font.system(size: 24, weight: .bold)
    /// Body copy (kb-body, 15pt)
    static let bodyText = Font.system(size: 15, weight: .regular)

    /// Giant timer numeral (kb-timer, 116pt mono)
    static let timerXL = Font.system(size: 116, weight: .bold, design: .monospaced)
    /// Medium timer (kb-timer-md, 72pt mono)
    static let timerLg = Font.system(size: 72, weight: .bold, design: .monospaced)
    /// Small timer (kb-timer-sm, 44pt mono)
    static let timerMd = Font.system(size: 44, weight: .bold, design: .monospaced)
    /// Big mono numeral used by Home dials (72pt)
    static let numeral = Font.system(size: 72, weight: .bold, design: .monospaced)
    /// Detail-hero mono numeral (56pt)
    static let numeralLg = Font.system(size: 56, weight: .bold, design: .monospaced)
    /// Standalone mono helper for inline tabular figures
    static func mono(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced)
    }

    // MARK: - Legacy styles (kept so pre-overhaul views still compile)
    static let timer = Font.system(size: 72, weight: .bold, design: .monospaced)
    static let roundCounter = Font.system(size: 24, weight: .semibold)
    static let sectionHeader = Font.system(size: 12, weight: .medium)
    static let body = Font.system(size: 16, weight: .regular)
    static let button = Font.system(size: 18, weight: .semibold)
    static let title = Font.system(size: 28, weight: .bold, design: .default)
}
