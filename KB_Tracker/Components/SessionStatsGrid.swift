// SessionStatsGrid.swift
// KB_Tracker
//
// 2×2 StatTile grid for a finished session (complete.jsx / history.jsx).
// Press: reps / ladders / time / avg ladder. Otherwise: total / avg set /
// fastest, then overtime count (EMOM) or slowest set (Rounds).

import SwiftUI

struct SessionStatsGrid: View {
    let session: WorkoutSession
    var spacing: CGFloat = 10

    var body: some View {
        let columns = [GridItem(.flexible(), spacing: spacing), GridItem(.flexible(), spacing: spacing)]
        LazyVGrid(columns: columns, spacing: spacing) {
            if session.workoutType == .press {
                let avgLadder = session.completedLadders > 0
                    ? session.totalDuration / Double(session.completedLadders) : 0
                StatTile(label: "TOTAL REPS", value: "\(session.totalReps)")
                StatTile(label: "LADDERS", value: "\(session.completedLadders)/\(session.targetLadders)")
                StatTile(label: "TIME", value: session.totalDuration.formattedMinutesSecondsPadded)
                StatTile(label: "AVG · LADDER", value: avgLadder.formattedMinutesSecondsPadded)
            } else {
                let times = session.setTimes
                StatTile(label: "TOTAL", value: session.totalDuration.formattedMinutesSecondsPadded)
                StatTile(label: "AVG SET", value: (session.averageSetTime ?? 0).formattedMinutesSecondsPadded)
                StatTile(label: "FASTEST", value: (times.min() ?? 0).formattedMinutesSecondsPadded)
                if session.mode == .emom {
                    let overtimeCount = times.filter { $0 > 60 }.count
                    StatTile(label: "OVERTIME", value: "\(overtimeCount)", warn: overtimeCount > 0)
                } else {
                    StatTile(label: "SLOWEST", value: (times.max() ?? 0).formattedMinutesSecondsPadded)
                }
            }
        }
    }
}
