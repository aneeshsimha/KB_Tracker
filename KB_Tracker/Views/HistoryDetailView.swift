// HistoryDetailView.swift
// KB_Tracker
//
// Expanded view of a single workout session
// Full implementation in Phase 6

import SwiftUI

struct HistoryDetailView: View {
    let session: WorkoutSession

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Date
                    Text(session.date.formatted(date: .complete, time: .shortened))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)

                    // Main Stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.roundsDisplay)
                            .font(AppTypography.title)
                            .foregroundColor(AppColors.textPrimary)
                        + Text(" ROUNDS")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Details Grid
                    VStack(alignment: .leading, spacing: 16) {
                        detailRow(label: "Weight", value: session.weightDisplay)
                        detailRow(label: "Mode", value: session.mode == .emom ? "EMOM" : "Rounds")

                        if let avgTime = session.averageSetTime {
                            detailRow(label: "Avg Set Time", value: formatTime(avgTime))
                        }

                        if session.totalDuration > 0 {
                            detailRow(label: "Total Time", value: formatTime(session.totalDuration))
                        }
                    }
                    .padding(16)
                    .background(AppColors.surface)
                    .cornerRadius(8)

                    // Notes
                    if let notes = session.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES")
                                .font(AppTypography.sectionHeader)
                                .foregroundColor(AppColors.textSecondary)

                            Text(notes)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 {
            return String(format: "%d:%02d", mins, secs)
        } else {
            return "\(secs)s"
        }
    }
}

#Preview {
    NavigationStack {
        HistoryDetailView(session: WorkoutSession(
            mode: .emom,
            kettlebellType: .double,
            weight: 20,
            targetRounds: 20
        ))
    }
}
