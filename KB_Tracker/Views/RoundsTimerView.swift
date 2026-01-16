// RoundsTimerView.swift
// KB_Tracker
//
// Active workout screen for Rounds-with-Rest mode

import SwiftUI

enum RoundsPhase {
    case getReady    // 5-second countdown before start
    case working     // User is doing the set
    case resting     // Rest countdown between sets
    case complete    // Workout finished
}

struct RoundsTimerView: View {
    let kettlebellType: KBType
    let weight: Int
    let targetRounds: Int
    let restDuration: Int

    @Environment(\.dismiss) private var dismiss

    // Timer state
    @State private var currentRound: Int = 0
    @State private var phase: RoundsPhase = .getReady
    @State private var getReadyCountdown: Int = 5
    @State private var restCountdown: Int = 0
    @State private var totalElapsed: TimeInterval = 0
    @State private var setTimes: [TimeInterval] = []
    @State private var setStartTime: Date? = nil
    @State private var currentSetElapsed: TimeInterval = 0
    @State private var lastBeepSecond: Int = -1
    @State private var getReadyStartTime: Date? = nil
    @State private var restStartTime: Date? = nil
    @State private var completedSession: WorkoutSession? = nil

    // Timer
    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                header

                Spacer()

                // Main display based on phase
                mainDisplay

                // Round counter
                if phase != .getReady {
                    Text("ROUND \(currentRound)/\(targetRounds)")
                        .font(AppTypography.roundCounter)
                        .foregroundColor(AppColors.textPrimary)
                }

                // Total elapsed time
                if phase != .getReady && phase != .complete {
                    Text("Total: \(formatTime(totalElapsed))")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                // Action button
                actionButton

                // Last set time
                if let lastTime = setTimes.last, phase != .getReady {
                    Text("Last set: \(formatTime(lastTime))")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(24)
        }
        .navigationBarHidden(true)
        .onAppear {
            startWorkout()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(weightDisplay)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(action: exitWorkout) {
                Image(systemName: "xmark")
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Main Display

    @ViewBuilder
    private var mainDisplay: some View {
        switch phase {
        case .getReady:
            VStack(spacing: 16) {
                Text("GET READY")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textSecondary)
                Text("\(getReadyCountdown)")
                    .font(AppTypography.timer)
                    .foregroundColor(AppColors.textPrimary)
                    .monospacedDigit()
            }

        case .working:
            VStack(spacing: 16) {
                Text("WORKING")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.accent)
                Text(formatTime(currentSetElapsed))
                    .font(AppTypography.timer)
                    .foregroundColor(AppColors.textPrimary)
                    .monospacedDigit()
            }

        case .resting:
            VStack(spacing: 16) {
                Text("REST")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textSecondary)
                Text("\(restCountdown)")
                    .font(AppTypography.timer)
                    .foregroundColor(restCountdown <= 5 ? AppColors.warning : AppColors.textPrimary)
                    .monospacedDigit()
            }

        case .complete:
            VStack(spacing: 16) {
                Text("COMPLETE!")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.accent)
                Text("\(currentRound)/\(targetRounds)")
                    .font(AppTypography.timer)
                    .foregroundColor(AppColors.textPrimary)
                Text("rounds")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        switch phase {
        case .getReady:
            EmptyView()

        case .working:
            Button(action: setDone) {
                Text("SET DONE")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(AppColors.accent)
                    .cornerRadius(8)
            }

        case .resting:
            Button(action: skipRest) {
                Text("SKIP REST")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.surface)
                    .cornerRadius(8)
            }

        case .complete:
            if let session = completedSession {
                NavigationLink(destination: SummaryView(session: session)) {
                    Text("VIEW SUMMARY")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accent)
                        .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Timer Logic

    private func startWorkout() {
        getReadyStartTime = Date()
        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            handleTimerTick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func handleTimerTick() {
        switch phase {
        case .getReady:
            handleGetReadyPhase()

        case .working:
            handleWorkingPhase()

        case .resting:
            handleRestingPhase()

        case .complete:
            break
        }
    }

    private func handleGetReadyPhase() {
        guard let start = getReadyStartTime else { return }

        let elapsed = Date().timeIntervalSince(start)
        let newCountdown = max(0, 5 - Int(elapsed))

        if newCountdown != getReadyCountdown {
            getReadyCountdown = newCountdown

            // Warning beeps during countdown
            if getReadyCountdown > 0 && getReadyCountdown <= 5 {
                AudioManager.shared.playCountdownBeep()
            }

            // Transition to working
            if getReadyCountdown == 0 {
                AudioManager.shared.playGoBeep()
                phase = .working
                currentRound = 1
                setStartTime = Date()
            }
        }
    }

    private func handleWorkingPhase() {
        totalElapsed += 0.1
        if let start = setStartTime {
            currentSetElapsed = Date().timeIntervalSince(start)
        }
    }

    private func handleRestingPhase() {
        totalElapsed += 0.1

        guard let start = restStartTime else { return }

        let elapsed = Date().timeIntervalSince(start)
        let newCountdown = max(0, restDuration - Int(elapsed))

        if newCountdown != restCountdown {
            restCountdown = newCountdown

            // Warning beeps at 5, 4, 3, 2, 1
            if restCountdown > 0 && restCountdown <= 5 && restCountdown != lastBeepSecond {
                AudioManager.shared.playCountdownBeep()
                lastBeepSecond = restCountdown
            }

            // Rest complete - transition to next round
            if restCountdown == 0 {
                transitionToNextRound()
            }
        }
    }

    // MARK: - Actions

    private func setDone() {
        guard phase == .working, let start = setStartTime else { return }

        // Record set time
        let setTime = Date().timeIntervalSince(start)
        setTimes.append(setTime)

        // Check if workout complete
        if currentRound >= targetRounds {
            phase = .complete
            AudioManager.shared.playCompletionSound()
            stopTimer()

            // Create WorkoutSession
            let session = WorkoutSession(
                mode: .rounds,
                kettlebellType: kettlebellType,
                weight: weight,
                targetRounds: targetRounds,
                restDuration: restDuration
            )
            session.completedRounds = currentRound
            session.totalDuration = totalElapsed
            session.setTimes = setTimes
            completedSession = session
        } else {
            // Start rest period
            phase = .resting
            restCountdown = restDuration
            restStartTime = Date()
            lastBeepSecond = -1
        }
    }

    private func skipRest() {
        transitionToNextRound()
    }

    private func transitionToNextRound() {
        AudioManager.shared.playGoBeep()
        currentRound += 1
        phase = .working
        setStartTime = Date()
        currentSetElapsed = 0
        lastBeepSecond = -1
    }

    private func exitWorkout() {
        stopTimer()
        dismiss()
    }

    // MARK: - Helpers

    private var weightDisplay: String {
        switch kettlebellType {
        case .single:
            return "\(weight)kg"
        case .double:
            return "2×\(weight)kg"
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    RoundsTimerView(kettlebellType: .double, weight: 20, targetRounds: 5, restDuration: 30)
}
