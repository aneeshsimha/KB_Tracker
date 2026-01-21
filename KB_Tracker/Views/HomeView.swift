// HomeView.swift
// KB_Tracker
//
// Main screen - workout configuration and start

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var mode: WorkoutMode = .emom
    @State private var kettlebellType: KBType = .double
    @State private var weight: Int = 20
    @State private var targetMinutes: Int = 20       // EMOM
    @State private var targetRounds: Int = 15        // Rounds mode
    @State private var restDuration: Int = 60        // Rounds mode
    @State private var showingWorkout: Bool = false

    private var lastSession: WorkoutSession? {
        sessions.first(where: { $0.isCompleted })
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App Title
                    Text("ARMOR")
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)

                    // Last Workout Card
                    if let last = lastSession {
                        lastWorkoutCard(session: last)
                    }

                    // Mode Toggle
                    modeToggle

                    // Weight Picker
                    WeightPicker(
                        kettlebellType: $kettlebellType,
                        weight: $weight
                    )

                    // Duration Picker
                    DurationPicker(
                        mode: mode,
                        minutes: $targetMinutes,
                        rounds: $targetRounds,
                        restSeconds: $restDuration
                    )

                    // START Button
                    startButton

                    // History Link
                    NavigationLink(destination: HistoryView()) {
                        Text("History")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .onAppear {
            prefillFromLastSession()
        }
        .onChange(of: mode) { _, newValue in
            // Sync rounds with EMOM minutes when switching to ROUNDS mode
            if newValue == .rounds {
                targetRounds = targetMinutes
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Last Workout Card

    private func lastWorkoutCard(session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LAST WORKOUT")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textSecondary)

            Text("\(session.weightDisplay) · \(session.roundsDisplay) rounds")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)

            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(8)
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        Picker("Mode", selection: $mode) {
            Text("EMOM").tag(WorkoutMode.emom)
            Text("ROUNDS").tag(WorkoutMode.rounds)
        }
        .pickerStyle(.segmented)
        .colorMultiply(AppColors.textPrimary)
    }

    // MARK: - Start Button

    private var startButton: some View {
        NavigationLink(destination: destinationView) {
            Text("START")
                .font(AppTypography.button)
                .foregroundColor(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.accent)
                .cornerRadius(8)
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        if mode == .emom {
            EMOMTimerView(
                config: .emom(
                    kettlebellType: kettlebellType,
                    weight: weight,
                    minutes: targetMinutes
                )
            )
        } else {
            RoundsTimerView(
                config: .rounds(
                    kettlebellType: kettlebellType,
                    weight: weight,
                    rounds: targetRounds,
                    restSeconds: restDuration
                )
            )
        }
    }

    // MARK: - Prefill Logic

    private func prefillFromLastSession() {
        guard let last = lastSession else { return }
        mode = last.mode
        kettlebellType = last.kettlebellType
        weight = last.weight

        if last.mode == .emom {
            targetMinutes = last.targetRounds
        } else {
            targetRounds = last.targetRounds
            restDuration = last.restDuration ?? 60
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
