// SparkBars.swift
// KB_Tracker
//
// Mini set-time bar chart (home.jsx Spark / history.jsx MicroSpark).
// EMOM bars over 60s render red; otherwise the supplied bar color.

import SwiftUI

struct SparkBars: View {
    let times: [TimeInterval]
    let mode: WorkoutMode
    var height: CGFloat = 28
    var spacing: CGFloat = 3
    var cornerRadius: CGFloat = 2
    var barColor: Color = AppColors.ink2
    /// Cap the number of bars (history rows show first 20).
    var limit: Int? = nil

    private var shown: [TimeInterval] {
        if let limit { return Array(times.prefix(limit)) }
        return times
    }

    var body: some View {
        let maxVal = max(shown.max() ?? 1, mode == .emom ? 60 : 1)
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(Array(shown.enumerated()), id: \.offset) { _, t in
                let over = mode == .emom && t > 60
                let h = max(cornerRadius + 1, min(t, maxVal) / maxVal * height)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(over ? AppColors.red : barColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: h)
            }
        }
        .frame(height: height, alignment: .bottom)
    }
}
