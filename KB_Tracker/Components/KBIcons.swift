// KBIcons.swift
// KB_Tracker
//
// Icon glyphs (SF Symbols matched to theme.jsx Icons) + circular IconButton.

import SwiftUI

enum KBIcon: String {
    case back    = "chevron.left"
    case close   = "xmark"
    case history = "clock.arrow.circlepath"
    case chevron = "chevron.right"
    case plus    = "plus"
    case minus   = "minus"
    case trash   = "trash"
    case share   = "square.and.arrow.up"
    case gear    = "gearshape"
    case chart   = "chart.bar"
}

/// Circular icon button (kb IconBtn): surface fill, hairline border.
struct IconButton: View {
    let icon: KBIcon
    var color: Color = AppColors.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon.rawValue)
                .font(.system(size: 32 * 0.42, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(AppColors.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppColors.hairline, lineWidth: 1))
        }
        .buttonStyle(TapScaleStyle())
    }
}
