// TimerViewModel.swift
// KB_Tracker
//
// Shared timer logic for EMOM and Rounds workout modes

import Foundation
import Combine

@MainActor
class TimerViewModel: ObservableObject {
    // MARK: - Configuration
    let config: WorkoutConfig

    // MARK: - Timer State
    @Published private(set) var currentRound: Int = 0
    @Published private(set) var totalElapsed: TimeInterval = 0
    @Published private(set) var setTimes: [TimeInterval] = []
    @Published private(set) var isSetInProgress: Bool = false

    // MARK: - EMOM-specific State
    @Published private(set) var emomPhase: TimerPhase = .getReady
    @Published private(set) var secondsIntoMinute: Double = 0
    @Published private(set) var getReadyCountdown: Int = WorkoutParameters.getReadySeconds

    // MARK: - Rounds-specific State
    @Published private(set) var roundsPhase: RoundsPhase = .getReady
    @Published private(set) var restCountdown: Int = 0
    @Published private(set) var currentSetElapsed: TimeInterval = 0

    // MARK: - Session State
    @Published private(set) var completedSession: WorkoutSession? = nil
    @Published private(set) var partialSession: WorkoutSession? = nil

    // MARK: - Private State
    private let audio: AudioCueing
    private let now: () -> Date
    private var setStartTime: Date? = nil
    private var getReadyStartTime: Date? = nil
    private var restStartTime: Date? = nil
    private var lastBeepSecond: Int = -1
    private var timer: AnyCancellable? = nil

    // MARK: - Computed Properties

    var isComplete: Bool {
        config.mode == .emom ? emomPhase == .complete : roundsPhase == .complete
    }

    var countdownSeconds: Int {
        if isOvertime {
            return Int(secondsIntoMinute) - 60
        } else {
            return 60 - Int(secondsIntoMinute)
        }
    }

    var isOvertime: Bool {
        secondsIntoMinute > 60 && isSetInProgress
    }

    var weightDisplay: String {
        config.weightDisplay
    }

    // MARK: - Initialization

    init(config: WorkoutConfig, audio: AudioCueing = AudioService.shared, now: @escaping () -> Date = Date.init) {
        self.config = config
        self.audio = audio
        self.now = now
    }

    // MARK: - Timer Control

    func start() {
        getReadyStartTime = now()
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

    // MARK: - Timer Logic

    // internal for testability — production callers go through startTimer()/Combine
    func tick() {
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

    func handleEMOMSetDone() {
        guard isSetInProgress, let startTime = setStartTime else { return }

        let setDuration = now().timeIntervalSince(startTime)
        setTimes.append(setDuration)

        isSetInProgress = false
        setStartTime = nil

        if currentRound >= config.targetMinutes {
            completeWorkout()
        }
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

        let elapsed = now().timeIntervalSince(start)
        let newCountdown = max(0, WorkoutParameters.getReadySeconds - Int(elapsed))

        if newCountdown != getReadyCountdown {
            getReadyCountdown = newCountdown

            if getReadyCountdown > 0 && getReadyCountdown <= WorkoutParameters.getReadySeconds {
                audio.playCountdownBeep()
            }

            if getReadyCountdown == 0 {
                audio.playGoBeep()
                roundsPhase = .working
                currentRound = 1
                setStartTime = now()
            }
        }
    }

    private func handleRoundsWorking() {
        totalElapsed += 0.1
        if let start = setStartTime {
            currentSetElapsed = now().timeIntervalSince(start)
        }
    }

    private func handleRoundsResting() {
        totalElapsed += 0.1

        guard let start = restStartTime else { return }

        let elapsed = now().timeIntervalSince(start)
        let restDuration = config.restDuration ?? 60
        let newCountdown = max(0, restDuration - Int(elapsed))

        if newCountdown != restCountdown {
            restCountdown = newCountdown

            if restCountdown > 0 && restCountdown <= 5 && restCountdown != lastBeepSecond {
                audio.playCountdownBeep()
                lastBeepSecond = restCountdown
            }

            if restCountdown == 0 {
                transitionToNextRound()
            }
        }
    }

    func handleRoundsSetDone() {
        guard roundsPhase == .working, let start = setStartTime else { return }

        let setTime = now().timeIntervalSince(start)
        setTimes.append(setTime)

        if currentRound >= config.targetRounds {
            roundsPhase = .complete
            audio.playCompletionSound()
            stop()
            createCompletedSession()
        } else {
            roundsPhase = .resting
            restCountdown = config.restDuration ?? 60
            restStartTime = now()
            lastBeepSecond = -1
        }
    }

    func skipRest() {
        transitionToNextRound()
    }

    private func transitionToNextRound() {
        audio.playGoBeep()
        currentRound += 1
        roundsPhase = .working
        setStartTime = now()
        currentSetElapsed = 0
        lastBeepSecond = -1
    }

    // MARK: - Workout Completion

    private func completeWorkout() {
        if config.mode == .emom {
            emomPhase = .complete
        } else {
            roundsPhase = .complete
        }
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
        session.completedRounds = currentRound
        session.totalDuration = totalElapsed
        session.setTimes = setTimes
        session.isCompleted = false

        partialSession = session
    }

    var session: WorkoutSession? {
        completedSession ?? partialSession
    }
}
