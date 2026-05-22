// Eyebrow.swift
// KB_Tracker
//
// Uppercase mono micro-label (kb-eyebrow): mono 11pt, .18em tracking, ink3.

import SwiftUI

struct Eyebrow: View {
    let text: String
    var color: Color = AppColors.ink3
    var size: CGFloat = 11

    init(_ text: String, color: Color = AppColors.ink3, size: CGFloat = 11) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .medium, design: .monospaced))
            .textCase(.uppercase)
            .kerning(size * 0.18)
            .foregroundColor(color)
    }
}
