// RoundDots.swift
// KB_Tracker
//
// Round progress indicator (timer.jsx RoundDots). Dots for ≤18 rounds,
// collapses to a progress bar above that.

import SwiftUI

struct RoundDots: View {
    let total: Int
    /// 0-indexed current round.
    let current: Int

    var body: some View {
        if total > 18 {
            GeometryReader { geo in
                let fraction = total > 0 ? CGFloat(current) / CGFloat(total) : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.surface2)
                    Capsule().fill(AppColors.ink)
                        .frame(width: max(0, geo.size.width * fraction))
                }
            }
            .frame(height: 6)
        } else {
            HStack(spacing: 6) {
                ForEach(0..<total, id: \.self) { i in
                    let isCurrent = i == current
                    let isDone = i < current
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(isDone ? AppColors.ink : AppColors.surface3)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .fill(isCurrent ? AppColors.red : Color.clear)
                                .frame(width: 6, height: 6)
                        )
                        .overlay(
                            Circle()
                                .stroke(isCurrent ? AppColors.redDim : Color.clear, lineWidth: 3)
                                .frame(width: 6, height: 6)
                        )
                }
                Spacer(minLength: 0)
            }
        }
    }
}
