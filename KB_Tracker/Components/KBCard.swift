// KBCard.swift
// KB_Tracker
//
// Card surface (kb-card): surface bg, 20pt radius, hairline border.

import SwiftUI

extension View {
    /// Wrap content in the standard card surface. Apply your own padding first.
    func kbCard(cornerRadius: CGFloat = 20,
                fill: Color = AppColors.surface,
                stroke: Color = AppColors.hairline) -> some View {
        self
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
    }
}

/// Container variant for when a wrapping view reads cleaner than a modifier.
struct KBCard<Content: View>: View {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .kbCard(cornerRadius: cornerRadius)
    }
}
