// EMOMTimerView.swift
// KB_Tracker
//
// Active workout screen for EMOM mode
// Full implementation in Phase 4

import SwiftUI

struct EMOMTimerView: View {
    let kettlebellType: KBType
    let weight: Int
    let targetMinutes: Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header with weight and exit
                HStack {
                    Text(weightDisplay)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                // Placeholder for timer
                Text("EMOM Timer")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)

                Text("\(targetMinutes) minutes")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)

                Text("Coming in Phase 4")
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                // Back button
                Button(action: { dismiss() }) {
                    Text("Back to Home")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.surface)
                        .cornerRadius(8)
                }
            }
            .padding(24)
        }
        .navigationBarHidden(true)
    }

    private var weightDisplay: String {
        switch kettlebellType {
        case .single:
            return "\(weight)kg"
        case .double:
            return "2×\(weight)kg"
        }
    }
}

#Preview {
    EMOMTimerView(kettlebellType: .double, weight: 20, targetMinutes: 20)
}
