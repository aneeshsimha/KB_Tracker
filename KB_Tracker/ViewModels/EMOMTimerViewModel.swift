// EMOMTimerViewModel.swift
// KB_Tracker
//
// EMOM-only timer state machine.

import Foundation
import Combine

@MainActor
final class EMOMTimerViewModel: ObservableObject {

    // MARK: - Configuration
    let config: WorkoutConfig

    // MARK: - Published State
    @Published private(set) var currentRound: Int = 0
    @Published private(set) var totalElapsed: TimeInterval = 0
    @Published private(set) var setTimes: [TimeInterval] = []
    @Published private(set) var isSetInProgress: Bool = false
    @Published private(set) var emomPhase: TimerPhase = .getReady
    @Published private(set) var secondsIntoMinute: Double = 0
    @Published private(set) var getReadyCountdown: Int = WorkoutParameters.getReadySeconds
    @Published private(set) var completedSession: WorkoutSession? = nil
    @Published private(set) var partialSession: WorkoutSession? = nil

    // MARK: - Private State
    private let audio: AudioCueing
    private let now: () -> Date
    private var setStartTime: Date? = nil
    private var lastBeepSecond: Int = -1
    private var timer: AnyCancellable? = nil

    // MARK: - Computed Properties

    var isComplete: Bool { emomPhase == .complete }

    var isOvertime: Bool { secondsIntoMinute > 60 && isSetInProgress }

    var countdownSeconds: Int {
        if isOvertime {
            return Int(secondsIntoMinute) - 60
        } else {
            return 60 - Int(secondsIntoMinute)
        }
    }

    var session: WorkoutSession? { completedSession ?? partialSession }

    // MARK: - Initialization

    init(config: WorkoutConfig, audio: AudioCueing = AudioService.shared, now: @escaping () -> Date = Date.init) {
        self.config = config
        self.audio = audio
        self.now = now
    }

    // MARK: - Timer Control

    func start() {
        startTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func startTimer() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    // MARK: - Timer Logic (internal for testability)

    func tick() {
        switch emomPhase {
        case .getReady:
            handleEMOMGetReady()
        case .active:
            handleEMOMActive()
        case .complete:
            break
        }
    }

    // MARK: - EMOM Logic

    private func handleEMOMGetReady() {
        getReadyCountdown = WorkoutParameters.getReadySeconds - Int(totalElapsed)

        let currentSecond = Int(totalElapsed)
        if currentSecond != lastBeepSecond && currentSecond < WorkoutParameters.getReadySeconds {
            audio.playCountdownBeep()
            lastBeepSecond = currentSecond
        }

        totalElapsed += 0.1

        if totalElapsed >= Double(WorkoutParameters.getReadySeconds) {
            emomPhase = .active
            totalElapsed = 0
            secondsIntoMinute = 0
            startNewEMOMRound()
            audio.playGoBeep()
        }
    }

    private func handleEMOMActive() {
        totalElapsed += 0.1
        secondsIntoMinute += 0.1

        // Countdown beeps at :55-59
        let secondsRemaining = 60 - Int(secondsIntoMinute)
        if secondsRemaining <= 5 && secondsRemaining > 0 {
            let beepSecond = 60 - secondsRemaining
            if beepSecond != lastBeepSecond {
                audio.playCountdownBeep()
                lastBeepSecond = beepSecond
            }
        }

        // Check for minute boundary (only if set is done)
        if secondsIntoMinute >= 60 && !isSetInProgress {
            secondsIntoMinute = 0
            lastBeepSecond = -1

            if currentRound < config.targetMinutes {
                startNewEMOMRound()
                audio.playGoBeep()
            } else {
                completeWorkout()
            }
        }
    }

    private func startNewEMOMRound() {
        currentRound += 1
        isSetInProgress = true
        setStartTime = now()
    }

    func setDone() {
        guard isSetInProgress, let startTime = setStartTime else { return }

        let setDuration = now().timeIntervalSince(startTime)
        setTimes.append(setDuration)

        isSetInProgress = false
        setStartTime = nil

        if currentRound >= config.targetMinutes {
            completeWorkout()
        }
    }

    // MARK: - Workout Completion

    private func completeWorkout() {
        emomPhase = .complete
        audio.playCompletionSound()
        stop()
        createCompletedSession()
    }

    private func createCompletedSession() {
        let session = WorkoutSession(
            mode: config.mode,
            kettlebellType: config.kettlebellType,
            weight: config.weight,
            targetRounds: config.targetRounds,
            restDuration: config.restDuration
        )
        session.workoutType = config.workoutType
        session.completedRounds = currentRound
        session.totalDuration = totalElapsed
        session.setTimes = setTimes
        session.isCompleted = true
        completedSession = session
    }

    func savePartialWorkout() {
        stop()

        let session = WorkoutSession(
            mode: config.mode,
            kettlebellType: config.kettlebellType,
            weight: config.weight,
            targetRounds: config.targetRounds,
            restDuration: config.restDuration
        )
        session.workoutType = config.workoutType
        session.completedRounds = currentRound
        session.totalDuration = totalElapsed
        session.setTimes = setTimes
        session.isCompleted = false

        partialSession = session
    }
}
