// TimerViewModel.swift
// KB_Tracker
//
// Shared timer logic for EMOM and Rounds modes

import Foundation
import Combine

class TimerViewModel: ObservableObject {
    // MARK: - Configuration

    let config: WorkoutConfig

    // MARK: - Published State

    @Published var currentRound: Int = 0
    @Published var totalElapsed: TimeInterval = 0
    @Published var setTimes: [TimeInterval] = []
    @Published var isSetInProgress: Bool = false

    // EMOM specific
    @Published var emomPhase: TimerPhase = .getReady
    @Published var secondsIntoMinute: Double = 0

    // Rounds specific
    @Published var roundsPhase: RoundsPhase = .getReady
    @Published var currentSetElapsed: TimeInterval = 0
    @Published var restCountdown: Int = 0

    // Shared
    @Published var getReadyCountdown: Int = 5

    // MARK: - Private State

    private var setStartTime: Date?
    private var getReadyStartTime: Date?
    private var restStartTime: Date?
    private var lastBeepSecond: Int = -1
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(config: WorkoutConfig) {
        self.config = config
    }

    // MARK: - Timer Control

    func start() {
        getReadyStartTime = Date()
        startTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.handleTimerTick()
        }
    }

    // MARK: - Timer Tick Handler

    private func handleTimerTick() {
        switch config.mode {
        case .emom:
            handleEMOMTick()
        case .rounds:
            handleRoundsTick()
        }
    }

    // MARK: - EMOM Logic

    private func handleEMOMTick() {
        switch emomPhase {
        case .getReady:
            handleEMOMGetReady()
        case .active:
            handleEMOMActive()
        case .complete:
            break
        }
    }

    private func handleEMOMGetReady() {
        getReadyCountdown = 5 - Int(totalElapsed)

        // Play countdown beeps
        let currentSecond = Int(totalElapsed)
        if currentSecond != lastBeepSecond && currentSecond < 5 {
            AudioService.shared.playCountdownBeep()
            lastBeepSecond = currentSecond
        }

        totalElapsed += 0.1

        if totalElapsed >= 5 {
            // Transition to active phase
            emomPhase = .active
            totalElapsed = 0
            secondsIntoMinute = 0
            startNewEMOMRound()
            AudioService.shared.playGoBeep()
        }
    }

    private func handleEMOMActive() {
        totalElapsed += 0.1
        secondsIntoMinute += 0.1

        // Check for countdown beeps at :55-59
        let secondsRemaining = 60 - Int(secondsIntoMinute)
        if secondsRemaining <= 5 && secondsRemaining > 0 {
            let beepSecond = 60 - secondsRemaining
            if beepSecond != lastBeepSecond {
                AudioService.shared.playCountdownBeep()
                lastBeepSecond = beepSecond
            }
        }

        // Check for minute boundary (only if set is done)
        if secondsIntoMinute >= 60 && !isSetInProgress {
            // Move to next minute
            secondsIntoMinute = 0
            lastBeepSecond = -1

            if currentRound < config.targetRounds {
                startNewEMOMRound()
                AudioService.shared.playGoBeep()
            } else {
                // Workout complete
                completeEMOMWorkout()
            }
        }
    }

    private func startNewEMOMRound() {
        currentRound += 1
        isSetInProgress = true
        setStartTime = Date()
    }

    func handleEMOMSetDone() {
        guard isSetInProgress, let startTime = setStartTime else { return }

        // Calculate set duration
        let setDuration = Date().timeIntervalSince(startTime)
        setTimes.append(setDuration)

        isSetInProgress = false
        setStartTime = nil

        // Check if this was the last round
        if currentRound >= config.targetRounds {
            completeEMOMWorkout()
        }
    }

    private func completeEMOMWorkout() {
        emomPhase = .complete
        stop()
        AudioService.shared.playCompletionSound()
    }

    // MARK: - Rounds Logic

    private func handleRoundsTick() {
        switch roundsPhase {
        case .getReady:
            handleRoundsGetReady()
        case .working:
            handleRoundsWorking()
        case .resting:
            handleRoundsResting()
        case .complete:
            break
        }
    }

    private func handleRoundsGetReady() {
        guard let start = getReadyStartTime else { return }

        let elapsed = Date().timeIntervalSince(start)
        let newCountdown = max(0, 5 - Int(elapsed))

        if newCountdown != getReadyCountdown {
            getReadyCountdown = newCountdown

            // Warning beeps during countdown
            if getReadyCountdown > 0 && getReadyCountdown <= 5 {
                AudioService.shared.playCountdownBeep()
            }

            // Transition to working
            if getReadyCountdown == 0 {
                AudioService.shared.playGoBeep()
                roundsPhase = .working
                currentRound = 1
                setStartTime = Date()
            }
        }
    }

    private func handleRoundsWorking() {
        totalElapsed += 0.1
        if let start = setStartTime {
            currentSetElapsed = Date().timeIntervalSince(start)
        }
    }

    private func handleRoundsResting() {
        totalElapsed += 0.1

        guard let start = restStartTime, let restDuration = config.restDuration else { return }

        let elapsed = Date().timeIntervalSince(start)
        let newCountdown = max(0, restDuration - Int(elapsed))

        if newCountdown != restCountdown {
            restCountdown = newCountdown

            // Warning beeps at 5, 4, 3, 2, 1
            if restCountdown > 0 && restCountdown <= 5 && restCountdown != lastBeepSecond {
                AudioService.shared.playCountdownBeep()
                lastBeepSecond = restCountdown
            }

            // Rest complete - transition to next round
            if restCountdown == 0 {
                transitionToNextRound()
            }
        }
    }

    func handleRoundsSetDone() {
        guard roundsPhase == .working, let start = setStartTime else { return }

        // Record set time
        let setTime = Date().timeIntervalSince(start)
        setTimes.append(setTime)

        // Check if workout complete
        if currentRound >= config.targetRounds {
            roundsPhase = .complete
            stop()
            AudioService.shared.playCompletionSound()
        } else {
            // Start rest period
            roundsPhase = .resting
            restCountdown = config.restDuration ?? 60
            restStartTime = Date()
            lastBeepSecond = -1
        }
    }

    func skipRest() {
        transitionToNextRound()
    }

    private func transitionToNextRound() {
        AudioService.shared.playGoBeep()
        currentRound += 1
        roundsPhase = .working
        setStartTime = Date()
        currentSetElapsed = 0
        lastBeepSecond = -1
    }

    // MARK: - Computed Properties

    var emomCountdownSeconds: Int {
        if isEMOMOvertime {
            return Int(secondsIntoMinute) - 60
        } else {
            return 60 - Int(secondsIntoMinute)
        }
    }

    var isEMOMOvertime: Bool {
        secondsIntoMinute > 60 && isSetInProgress
    }

    // MARK: - Session Creation

    func createSession(isCompleted: Bool = true) -> WorkoutSession {
        let session = WorkoutSession(
            mode: config.mode,
            kettlebellType: config.kettlebellType,
            weight: config.weight,
            targetRounds: config.targetRounds,
            restDuration: config.restDuration
        )
        session.completedRounds = currentRound
        session.totalDuration = totalElapsed
        session.setTimes = setTimes
        session.isCompleted = isCompleted
        return session
    }
}
