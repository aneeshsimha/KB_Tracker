// SegmentedToggle.swift
// KB_Tracker
//
// Two-option segmented control (kb-seg): selected = ink fill / bg text.

import SwiftUI

struct SegmentedOption<T: Hashable> {
    let label: String
    let value: T
}

struct SegmentedToggle<T: Hashable>: View {
    let options: [SegmentedOption<T>]
    @Binding var selection: T
    /// When true, renders the lighter "footer" variant used inside dials
    /// (transparent track, surface3 on the active segment).
    var inline: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, opt in
                let on = opt.value == selection
                let fg: Color = on ? (inline ? AppColors.ink : AppColors.background) : AppColors.ink2
                let bg: Color = on ? (inline ? AppColors.surface3 : AppColors.ink) : Color.clear
                Button {
                    selection = opt.value
                } label: {
                    Text(opt.label)
                        .font(.system(size: 14, weight: .semibold))
                        .kerning(14 * 0.08)
                        .textCase(.uppercase)
                        .foregroundColor(fg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(bg)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(inline ? 0 : 4)
        .background(inline ? Color.clear : AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(inline ? Color.clear : AppColors.hairline, lineWidth: 1)
        )
    }
}
