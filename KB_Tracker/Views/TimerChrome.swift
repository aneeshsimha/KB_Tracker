// TimerChrome.swift
// KB_Tracker
//
// Shared top bar for the active-workout timer screens (timer.jsx TimerChrome):
// an END pill button, a center eyebrow label, an "NN/NN" mono round counter,
// and a RoundDots progress row beneath.

import SwiftUI

struct TimerChrome: View {
    let label: String
    /// 0-indexed current round (drives both the "NN/NN" readout and dots).
    let current: Int
    let total: Int
    var accent: Color = AppColors.ink3
    let onEnd: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: onEnd) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                        Text("END")
                            .font(.system(size: 12, weight: .semibold))
                            .kerning(0.1)
                    }
                    .foregroundColor(AppColors.ink2)
                    .frame(height: 32)
                    .padding(.horizontal, 12)
                    .background(AppColors.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppColors.hairline, lineWidth: 1))
                }
                .buttonStyle(TapScaleStyle())

                Spacer()

                Eyebrow(label, color: accent)

                Spacer()

                Text("\(padded(current + 1))/\(padded(total))")
                    .font(AppTypography.mono(12, weight: .medium))
                    .foregroundColor(AppColors.ink3)
            }

            RoundDots(total: total, current: current)
        }
    }

    private func padded(_ value: Int) -> String {
        String(format: "%02d", max(0, value))
    }
}
