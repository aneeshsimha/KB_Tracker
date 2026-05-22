// SetChart.swift
// KB_Tracker
//
// Full set-time bar chart (complete.jsx / history.jsx SetChart).
// EMOM shows a dashed 60s reference line; over-60s bars render red.

import SwiftUI

struct SetChart: View {
    let setTimes: [TimeInterval]
    let mode: WorkoutMode
    var dense: Bool = false

    private var chartHeight: CGFloat { dense ? 80 : 130 }

    var body: some View {
        if setTimes.isEmpty {
            EmptyView()
        } else {
            let isEMOM = mode == .emom
            let maxRef = isEMOM ? max(60, setTimes.max() ?? 60) : (setTimes.max() ?? 1)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Eyebrow("Set Breakdown")
                    Spacer()
                    Eyebrow("\(setTimes.count) \(isEMOM ? "MIN" : "RDS")", color: AppColors.ink4)
                }

                ZStack(alignment: .bottom) {
                    // bars
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(Array(setTimes.enumerated()), id: \.offset) { _, t in
                            let over = isEMOM && t > 60
                            let h = max(4, CGFloat(t / maxRef) * chartHeight)
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(over ? AppColors.red : AppColors.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: h)
                        }
                    }
                    .frame(height: chartHeight, alignment: .bottom)

                    // 60s reference line (EMOM only)
                    if isEMOM {
                        let y = CGFloat(60.0 / maxRef) * chartHeight
                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .fill(AppColors.ink4)
                                .frame(height: 1)
                            Text("60s")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(AppColors.ink4)
                                .offset(y: -12)
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, y)
                    }
                }
                .frame(height: chartHeight)

                // axis labels: first / mid / last
                HStack {
                    Text("01")
                    Spacer()
                    if setTimes.count > 2 {
                        Text(String(format: "%02d", Int(ceil(Double(setTimes.count) / 2))))
                    }
                    Spacer()
                    Text(String(format: "%02d", setTimes.count))
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(AppColors.ink4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .kbCard()
        }
    }
}
