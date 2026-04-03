// HistoryDetailView.swift
// KB_Tracker
//
// Expanded view of a single workout session

import SwiftUI
import SwiftData

struct HistoryDetailView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @State private var isEditingNotes: Bool = false

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Date
                    Text(session.date.formatted(date: .complete, time: .shortened))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)

                    // Main Stats
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(session.roundsDisplay)
                                .font(AppTypography.title)
                                .foregroundColor(session.completedRounds >= session.targetRounds ? AppColors.accent : AppColors.warning)
                            Text("ROUNDS")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Text("completed / target")
                            .font(AppTypography.sectionHeader)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Details Grid
                    VStack(alignment: .leading, spacing: 16) {
                        detailRow(label: "Target Rounds", value: "\(session.targetRounds)")
                        detailRow(label: "Completed", value: "\(session.completedRounds)")
                        detailRow(label: "Weight", value: session.weightDisplay)
                        detailRow(label: "Mode", value: session.mode == .emom ? "EMOM" : "Rounds")

                        if let avgTime = session.averageSetTime {
                            detailRow(label: "Avg Set Time", value: avgTime.formattedSetTime)
                        }

                        if session.totalDuration > 0 {
                            detailRow(label: "Total Time", value: session.totalDuration.formattedMinutesSeconds)
                        }

                        if let rest = session.restDuration, session.mode == .rounds {
                            detailRow(label: "Rest Duration", value: "\(rest)s")
                        }
                    }
                    .padding(16)
                    .background(AppColors.surface)
                    .cornerRadius(8)

                    // Set Breakdown Section
                    if !session.setTimes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Header with optional overtime warning
                            HStack {
                                Text("SET BREAKDOWN")
                                    .font(AppTypography.sectionHeader)
                                    .foregroundColor(AppColors.textSecondary)

                                Spacer()

                                // Warning indicator if any overtime sets (EMOM mode only)
                                if session.hasOvertimeSets {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 12))
                                        Text("OVERTIME")
                                            .font(AppTypography.sectionHeader)
                                    }
                                    .foregroundColor(AppColors.warning)
                                }
                            }

                            // Set times grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], alignment: .leading, spacing: 8) {
                                ForEach(Array(session.setTimes.enumerated()), id: \.offset) { index, time in
                                    setTimeCell(round: index + 1, time: time)
                                }
                            }
                        }
                        .padding(16)
                        .background(AppColors.surface)
                        .cornerRadius(8)
                    }

                    // Editable Notes Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("NOTES")
                                .font(AppTypography.sectionHeader)
                                .foregroundColor(AppColors.textSecondary)

                            Spacer()

                            // Edit/Save toggle button
                            Button(action: {
                                if isEditingNotes {
                                    try? modelContext.save()
                                }
                                isEditingNotes.toggle()
                            }) {
                                Text(isEditingNotes ? "Save" : "Edit")
                                    .font(AppTypography.sectionHeader)
                                    .foregroundColor(AppColors.accent)
                            }
                        }

                        if isEditingNotes {
                            // Editable TextEditor
                            TextEditor(text: Binding(
                                get: { session.notes ?? "" },
                                set: { session.notes = $0.isEmpty ? nil : $0 }
                            ))
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .background(AppColors.surface)
                            .frame(minHeight: 100)
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        } else {
                            // Read-only display
                            if let notes = session.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textPrimary)
                            } else {
                                Text("No notes")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                                    .italic()
                            }
                        }
                    }
                    .padding(16)
                    .background(AppColors.surface)
                    .cornerRadius(8)
                }
                .padding(24)
            }
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Helper Views

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

    private func setTimeCell(round: Int, time: TimeInterval) -> some View {
        let isOvertime = session.mode == .emom && time > 60

        return HStack(spacing: 4) {
            Text("R\(round):")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textSecondary)

            Text(time.formattedSetTime)
                .font(AppTypography.body)
                .foregroundColor(isOvertime ? AppColors.warning : AppColors.textPrimary)

            if isOvertime {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.warning)
            }
        }
    }
}

#Preview {
    let sampleSession = WorkoutSession(
        mode: .emom,
        kettlebellType: .double,
        weight: 20,
        targetRounds: 20
    )
    sampleSession.setTimes = [42, 45, 48, 51, 55, 58, 62, 65, 48, 52]
    sampleSession.completedRounds = 10
    sampleSession.totalDuration = 600
    sampleSession.notes = "Grip started failing on round 7"

    return NavigationStack {
        HistoryDetailView(session: sampleSession)
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
