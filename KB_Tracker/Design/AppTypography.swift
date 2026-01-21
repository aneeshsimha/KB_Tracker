// AppTypography.swift
// KB_Tracker
//
// Design system typography definitions

import SwiftUI

struct AppTypography {
    // Timer display - large, monospace for alignment
    static let timer = Font.system(size: 72, weight: .bold, design: .monospaced)

    // Round counter
    static let roundCounter = Font.system(size: 24, weight: .semibold)

    // Section headers (WEIGHT, DURATION, etc.)
    static let sectionHeader = Font.system(size: 12, weight: .medium)

    // Body text
    static let body = Font.system(size: 16, weight: .regular)

    // Button labels
    static let button = Font.system(size: 18, weight: .semibold)

    // App title
    static let title = Font.system(size: 28, weight: .bold, design: .default)
}
