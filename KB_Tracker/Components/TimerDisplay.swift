// TimerDisplay.swift
// KB_Tracker
//
// Large countdown timer display component

import SwiftUI

struct TimerDisplay: View {
    let seconds: Int                   // Countdown value
    let isOvertime: Bool               // Show warning styling
    let label: String?                 // Optional label below (e.g., "ROUND 7/20")

    init(seconds: Int, isOvertime: Bool = false, label: String? = nil) {
        self.seconds = seconds
        self.isOvertime = isOvertime
        self.label = label
    }

    private var timeString: String {
        let absSeconds = abs(seconds)
        let mins = absSeconds / 60
        let secs = absSeconds % 60
        let sign = seconds < 0 ? "-" : ""
        return sign + String(format: "%d:%02d", mins, secs)
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
            TimerDisplay(seconds: 47, label: "ROUND 7/20")
            TimerDisplay(seconds: 5, label: "GET READY")
            TimerDisplay(seconds: -5, isOvertime: true, label: "OVERTIME")
        }
    }
}
