// HistoryView.swift
// KB_Tracker
//
// List of past workouts
// Full implementation in Phase 6

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            if sessions.isEmpty {
                VStack(spacing: 16) {
                    Text("No workouts yet")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)

                    Text("Complete your first workout to see it here")
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.textSecondary)
                }
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink(destination: HistoryDetailView(session: session)) {
                            sessionRow(session)
                        }
                        .listRowBackground(AppColors.surface)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func sessionRow(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 8) {
                Text(session.weightDisplay)
                    .foregroundColor(AppColors.textSecondary)
                Text("·")
                    .foregroundColor(AppColors.textSecondary)
                Text("\(session.completedRounds)/\(session.targetRounds) rounds")
                    .foregroundColor(session.completedRounds >= session.targetRounds ? AppColors.accent : AppColors.warning)
                Text("·")
                    .foregroundColor(AppColors.textSecondary)
                Text(session.mode == .emom ? "EMOM" : "Rounds")
                    .foregroundColor(AppColors.textSecondary)
            }
            .font(AppTypography.sectionHeader)

            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
