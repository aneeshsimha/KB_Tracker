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
    case check   = "checkmark"
    case plus    = "plus"
    case minus   = "minus"
    case trash   = "trash"
    case dots    = "ellipsis"
}

/// Circular icon button (kb IconBtn): surface fill, hairline border.
struct IconButton: View {
    let icon: KBIcon
    var color: Color = AppColors.ink
    var size: CGFloat = 32
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon.rawValue)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(AppColors.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppColors.hairline, lineWidth: 1))
        }
        .buttonStyle(TapScaleStyle())
    }
}
