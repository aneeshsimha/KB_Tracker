// StatTile.swift
// KB_Tracker
//
// Stat card (complete.jsx / history.jsx Stat): eyebrow label + big mono value.
// `warn` turns label + value red (used for EMOM overtime count).

import SwiftUI

struct StatTile: View {
    let label: String
    let value: String
    var warn: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(label, color: warn ? AppColors.red : AppColors.ink3)
            Text(value)
                .font(AppTypography.mono(28))
                .foregroundColor(warn ? AppColors.red : AppColors.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kbCard()
    }
}
