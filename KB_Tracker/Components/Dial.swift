// Dial.swift
// KB_Tracker
//
// Big-numeral ± tile used on Home (from home.jsx Dial + StepperBtn).

import SwiftUI

/// 36pt rounded ± button.
struct StepperButton: View {
    let icon: KBIcon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.ink)
                .frame(width: 36, height: 36)
                .background(AppColors.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppColors.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(TapScaleStyle())
    }
}

struct Dial<Footer: View>: View {
    let eyebrow: String
    let value: String
    let unit: String
    let onMinus: () -> Void
    let onPlus: () -> Void
    @ViewBuilder var footer: Footer

    init(eyebrow: String, value: String, unit: String,
         onMinus: @escaping () -> Void, onPlus: @escaping () -> Void,
         @ViewBuilder footer: () -> Footer = { EmptyView() }) {
        self.eyebrow = eyebrow
        self.value = value
        self.unit = unit
        self.onMinus = onMinus
        self.onPlus = onPlus
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Eyebrow(eyebrow)
                Spacer()
                HStack(spacing: 8) {
                    StepperButton(icon: .minus, action: onMinus)
                    StepperButton(icon: .plus, action: onPlus)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(value)
                    .font(AppTypography.numeral)
                    .foregroundColor(AppColors.ink)
                Eyebrow(unit, size: 12)
            }
            footer
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kbCard()
    }
}
