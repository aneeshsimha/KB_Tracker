// SummaryView.swift
// KB_Tracker
//
// Post-workout summary and notes

import SwiftUI
import SwiftData

struct SummaryView: View {
    let session: WorkoutSession
    var onSaveComplete: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var notes: String = ""
    @State private var showBreakdown: Bool = false
    @State private var showDiscardAlert: Bool = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with discard option
                    HStack {
                        Text("WORKOUT COMPLETE")
                            .font(AppTypography.title)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Button(action: { showDiscardAlert = true }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    // Main stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(session.completedRounds)/\(session.targetRounds) ROUNDS")
                            .font(AppTypography.roundCounter)
                            .foregroundColor(AppColors.textPrimary)

                        statRow(label: "Total Time", value: formatTime(session.totalDuration))
                        statRow(label: "Avg Set Time", value: formatTime(session.averageSetTime ?? 0))
                        statRow(label: "Weight", value: session.weightDisplay)
                    }

                    // Set breakdown
                    if !session.setTimes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: { showBreakdown.toggle() }) {
                                HStack {
                                    Text("SET BREAKDOWN")
                                        .font(AppTypography.sectionHeader)
                                        .foregroundColor(AppColors.textSecondary)
                                    Spacer()
                                    Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }

                            if showBreakdown {
                                setBreakdownView
                            }
                        }
                        .padding(16)
                        .background(AppColors.surface)
                        .cornerRadius(8)
                    }

                    // Notes input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES")
                            .font(AppTypography.sectionHeader)
                            .foregroundColor(AppColors.textSecondary)

                        TextField("Add notes about this workout...", text: $notes, axis: .vertical)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(12)
                            .background(AppColors.surface)
                            .cornerRadius(8)
                            .lineLimit(3...6)
                    }

                    // Save button
                    Button(action: saveWorkout) {
                        Text("SAVE")
                            .font(AppTypography.button)
                            .foregroundColor(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.accent)
                            .cornerRadius(8)
                    }
                }
                .padding(24)
            }
        }
        .navigationBarHidden(true)
        .interactiveDismissDisabled()
        .alert("Discard Workout?", isPresented: $showDiscardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("This workout will not be saved.")
        }
    }

    // MARK: - Components

    private func statRow(label: String, value: String) -> some View {
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

    private var setBreakdownView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(Array(session.setTimes.enumerated()), id: \.offset) { index, time in
                HStack(spacing: 4) {
                    Text("R\(index + 1):")
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.textSecondary)
                    Text(formatSetTime(time))
                        .font(AppTypography.body)
                        .foregroundColor(time > 60 ? AppColors.warning : AppColors.textPrimary)
                    if time > 60 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.warning)
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func saveWorkout() {
        session.notes = notes.isEmpty ? nil : notes
        session.isCompleted = true
        modelContext.insert(session)

        // Dismiss this view first
        dismiss()

        // Then dismiss the timer view to exit the entire workout flow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onSaveComplete?()
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func formatSetTime(_ seconds: TimeInterval) -> String {
        if seconds >= 60 {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return String(format: "%d:%02d", mins, secs)
        } else {
            return "\(Int(seconds))s"
        }
    }
}

#Preview {
    let session = WorkoutSession(
        mode: .emom,
        kettlebellType: .double,
        weight: 20,
        targetRounds: 20,
        restDuration: nil
    )
    session.completedRounds = 18
    session.totalDuration = 1140
    session.setTimes = [42, 45, 48, 51, 44, 47, 62, 55, 43, 46, 49, 52, 44, 47, 50, 53, 45, 48]

    return NavigationStack {
        SummaryView(session: session)
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
