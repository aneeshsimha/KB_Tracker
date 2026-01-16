// EMOMTimerView.swift
// KB_Tracker
//
// Active workout screen for EMOM mode

import SwiftUI
import SwiftData
import Combine

enum TimerPhase {
    case getReady
    case active
    case complete
}

struct EMOMTimerView: View {
    // Passed in from HomeView
    let kettlebellType: KBType
    let weight: Int
    let targetMinutes: Int

    // Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Timer state
    @State private var currentRound: Int = 0
    @State private var secondsIntoMinute: Double = 0
    @State private var totalElapsed: TimeInterval = 0
    @State private var setTimes: [TimeInterval] = []
    @State private var setStartTime: Date? = nil
    @State private var phase: TimerPhase = .getReady
    @State private var isSetInProgress: Bool = false
    @State private var getReadyCountdown: Int = 5
    @State private var lastBeepSecond: Int = -1

    // UI state
    @State private var showExitConfirmation: Bool = false
    @State private var navigateToSummary: Bool = false
    @State private var completedSession: WorkoutSession? = nil

    // Timer publisher
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                header

                Spacer()

                // Main timer display
                timerContent

                Spacer()

                // SET DONE button (only during active phase)
                if phase == .active {
                    setDoneButton
                }

                // Last set time
                if let lastTime = setTimes.last {
                    Text("Last set: \(formatTime(lastTime))")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(24)
        }
        .navigationBarHidden(true)
        .onReceive(timer) { _ in
            handleTimerTick()
        }
        .alert("Exit Workout?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Your progress will not be saved.")
        }
        .navigationDestination(isPresented: $navigateToSummary) {
            if let session = completedSession {
                SummaryView(session: session)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(weightDisplay)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(action: { showExitConfirmation = true }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Timer Content

    @ViewBuilder
    private var timerContent: some View {
        switch phase {
        case .getReady:
            VStack(spacing: 16) {
                Text("GET READY")
                    .font(AppTypography.roundCounter)
                    .foregroundColor(AppColors.textSecondary)
                TimerDisplay(seconds: getReadyCountdown, label: nil)
            }

        case .active:
            VStack(spacing: 16) {
                // Countdown display
                TimerDisplay(
                    seconds: countdownSeconds,
                    isOvertime: isOvertime,
                    label: "ROUND \(currentRound)/\(targetMinutes)"
                )

                // Total elapsed time
                Text("Total: \(formatTime(totalElapsed))")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }

        case .complete:
            VStack(spacing: 16) {
                Text("COMPLETE!")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)
                Text("\(currentRound) rounds")
                    .font(AppTypography.roundCounter)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - SET DONE Button

    private var setDoneButton: some View {
        Button(action: handleSetDone) {
            Text(isSetInProgress ? "SET DONE" : "WAITING...")
                .font(AppTypography.button)
                .foregroundColor(isSetInProgress ? AppColors.background : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(isSetInProgress ? AppColors.accent : AppColors.surface)
                .cornerRadius(8)
        }
        .disabled(!isSetInProgress)
    }

    // MARK: - Timer Logic

    private func handleTimerTick() {
        switch phase {
        case .getReady:
            handleGetReadyPhase()
        case .active:
            handleActivePhase()
        case .complete:
            break
        }
    }

    private func handleGetReadyPhase() {
        getReadyCountdown = 5 - Int(totalElapsed)

        // Play countdown beeps
        let currentSecond = Int(totalElapsed)
        if currentSecond != lastBeepSecond && currentSecond < 5 {
            AudioManager.shared.playCountdownBeep()
            lastBeepSecond = currentSecond
        }

        totalElapsed += 0.1

        if totalElapsed >= 5 {
            // Transition to active phase
            phase = .active
            totalElapsed = 0
            secondsIntoMinute = 0
            startNewRound()
            AudioManager.shared.playGoBeep()
        }
    }

    private func handleActivePhase() {
        totalElapsed += 0.1
        secondsIntoMinute += 0.1

        // Check for countdown beeps at :55-59
        let secondsRemaining = 60 - Int(secondsIntoMinute)
        if secondsRemaining <= 5 && secondsRemaining > 0 {
            let beepSecond = 60 - secondsRemaining
            if beepSecond != lastBeepSecond {
                AudioManager.shared.playCountdownBeep()
                lastBeepSecond = beepSecond
            }
        }

        // Check for minute boundary (only if set is done)
        if secondsIntoMinute >= 60 && !isSetInProgress {
            // Move to next minute
            secondsIntoMinute = 0
            lastBeepSecond = -1

            if currentRound < targetMinutes {
                startNewRound()
                AudioManager.shared.playGoBeep()
            } else {
                // Workout complete
                completeWorkout()
            }
        }
    }

    private func startNewRound() {
        currentRound += 1
        isSetInProgress = true
        setStartTime = Date()
    }

    private func handleSetDone() {
        guard isSetInProgress, let startTime = setStartTime else { return }

        // Calculate set duration
        let setDuration = Date().timeIntervalSince(startTime)
        setTimes.append(setDuration)

        isSetInProgress = false
        setStartTime = nil

        // Check if this was the last round
        if currentRound >= targetMinutes {
            completeWorkout()
        }
    }

    private func completeWorkout() {
        phase = .complete
        AudioManager.shared.playCompletionSound()

        // Create workout session
        let session = WorkoutSession(
            mode: .emom,
            kettlebellType: kettlebellType,
            weight: weight,
            targetRounds: targetMinutes,
            restDuration: nil
        )
        session.completedRounds = currentRound
        session.totalDuration = totalElapsed
        session.setTimes = setTimes
        session.isCompleted = true

        completedSession = session

        // Navigate to summary after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            navigateToSummary = true
        }
    }

    // MARK: - Computed Properties

    private var weightDisplay: String {
        switch kettlebellType {
        case .single:
            return "\(weight)kg"
        case .double:
            return "2×\(weight)kg"
        }
    }

    private var countdownSeconds: Int {
        if isOvertime {
            // Show negative time when overtime
            return Int(secondsIntoMinute) - 60
        } else {
            return 60 - Int(secondsIntoMinute)
        }
    }

    private var isOvertime: Bool {
        secondsIntoMinute > 60 && isSetInProgress
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    NavigationStack {
        EMOMTimerView(kettlebellType: .double, weight: 20, targetMinutes: 3)
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
