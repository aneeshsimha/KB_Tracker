// ComplexReminderRow.swift
// KB_Tracker
//
// Shared reminder row displaying CLN / PRS / SQT rep counts.

import SwiftUI

struct ComplexReminderRow: View {
    var body: some View {
        HStack(spacing: 22) {
            rep("2", "CLN")
            rep("1", "PRS")
            rep("3", "SQT")
        }
    }

    private func rep(_ n: String, _ label: String) -> some View {
        HStack(spacing: 6) {
            Text(n)
                .font(AppTypography.mono(16, weight: .bold))
                .foregroundColor(AppColors.ink)
            Text(label)
                .font(.system(size: 12))
                .kerning(0.5)
                .foregroundColor(AppColors.ink3)
        }
    }
}
