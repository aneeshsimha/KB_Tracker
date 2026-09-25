// TimerChrome.swift
// KB_Tracker
//
// Shared pieces for the active-workout timer screens (timer.jsx): the top bar
// (TimerChrome: an END pill button, a center eyebrow label, an "NN/NN" mono
// round counter, and a RoundDots progress row beneath), the get-ready
// countdown, and the Set Done footer.

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
                EndPill(action: onEnd)

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

/// "× END" capsule button that opens the end-session confirm.
struct EndPill: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
    }
}

/// Get-ready phase: eyebrow, giant countdown digit, and a load · target line.
struct GetReadyContent: View {
    let eyebrow: String
    let digit: Int
    let weight: String
    let detail: String

    var body: some View {
        VStack(spacing: 0) {
            Eyebrow(eyebrow, color: AppColors.ink3)
                .padding(.bottom, 16)

            Text("\(digit)")
                .font(.system(size: 220, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.ink)
                .monospacedDigit()
                .id(digit)
                .transition(.scale(scale: 0.94).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: digit)

            (
                Text(weight)
                    .font(AppTypography.mono(18, weight: .semibold))
                + Text("  ·  ")
                    .foregroundColor(AppColors.ink4)
                + Text(detail)
                    .font(.system(size: 14))
            )
            .foregroundColor(AppColors.ink2)
            .padding(.top, 20)
        }
    }
}

/// Big SET DONE button with the last / average set time beneath it.
struct SetDoneFooter: View {
    let setTimes: [TimeInterval]
    var overtime: Bool = false
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: action) {
                Text("Set Done")
                    .font(.system(size: 18, weight: .bold))
                    .kerning(18 * 0.08)
                    .textCase(.uppercase)
                    .foregroundColor(overtime ? AppColors.ink : AppColors.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 76)
                    .background(overtime ? AppColors.red : AppColors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(TapScaleStyle())

            if let last = setTimes.last {
                HStack {
                    lastAvg(label: "Last set", value: last)
                    Spacer()
                    lastAvg(label: "Avg", value: setTimes.reduce(0, +) / Double(setTimes.count))
                }
                .font(.system(size: 12))
                .foregroundColor(AppColors.ink3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private func lastAvg(label: String, value: TimeInterval) -> some View {
        HStack(spacing: 6) {
            Text("\(label):")
            Text(value.formattedMinutesSecondsPadded)
                .font(AppTypography.mono(12, weight: .semibold))
                .foregroundColor(AppColors.ink2)
        }
    }
}
