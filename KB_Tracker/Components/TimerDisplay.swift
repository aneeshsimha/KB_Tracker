// TimerDisplay.swift
// KB_Tracker
//
// Large countdown timer display component

import SwiftUI

struct TimerDisplay: View {
    let seconds: Int
    let isOvertime: Bool
    let label: String?

    private var timeString: String {
        let displaySeconds = abs(seconds)
        let mins = displaySeconds / 60
        let secs = displaySeconds % 60
        let prefix = seconds < 0 ? "-" : ""
        return prefix + String(format: "%d:%02d", mins, secs)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(timeString)
                .font(AppTypography.timer)
                .monospacedDigit()
                .foregroundColor(isOvertime ? AppColors.warning : AppColors.textPrimary)

            if let label = label {
                Text(label)
                    .font(AppTypography.roundCounter)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        VStack(spacing: 40) {
            TimerDisplay(seconds: 47, isOvertime: false, label: "ROUND 7/20")
            TimerDisplay(seconds: 5, isOvertime: false, label: "GET READY")
            TimerDisplay(seconds: -12, isOvertime: true, label: "OVERTIME")
        }
    }
}
