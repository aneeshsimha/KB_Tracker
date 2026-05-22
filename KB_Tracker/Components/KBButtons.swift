// KBButtons.swift
// KB_Tracker
//
// Primary / ghost buttons (kb-btn-primary, kb-btn-ghost) + tap-scale style.

import SwiftUI

/// Subtle press feedback shared by tappable surfaces (kb-tap).
struct TapScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// Big filled CTA — 64pt, 18pt radius, uppercase. Default white-on-black.
struct PrimaryButton: View {
    let title: String
    var background: Color = AppColors.ink
    var foreground: Color = AppColors.background
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: { if enabled { action() } }) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .kerning(17 * 0.08)
                .textCase(.uppercase)
                .foregroundColor(enabled ? foreground : AppColors.ink4)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(enabled ? background : AppColors.surface3)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(TapScaleStyle())
        .disabled(!enabled)
    }
}

/// Secondary outline button — 56pt, 16pt radius, surface fill + hairline.
struct GhostButton: View {
    let title: String
    var foreground: Color = AppColors.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .kerning(15 * 0.06)
                .textCase(.uppercase)
                .foregroundColor(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColors.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(TapScaleStyle())
    }
}
