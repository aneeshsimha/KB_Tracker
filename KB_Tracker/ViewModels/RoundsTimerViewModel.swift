// RoundsTimerViewModel.swift
// KB_Tracker
//
// Rounds-only timer state machine.

import Foundation
import Combine

@MainActor
final class RoundsTimerViewModel: ObservableObject {

    // MARK: - Configuration
    let config: WorkoutConfig

    // MARK: - Published State
    @Published private(set) var currentRound: Int = 0
    @Published private(set) var totalElapsed: TimeInterval = 0
    @Published private(set) var setTimes: [TimeInterval] = []
    @Published private(set) var roundsPhase: RoundsPhase = .getReady
    @Published private(set) var restCountdown: Int = 0
    @Published private(set) var currentSetElapsed: TimeInterval = 0
    @Published private(set) var completedSession: WorkoutSession? = nil
    @Published private(set) var partialSession: WorkoutSession? = nil
    @Published private(set) var getReadyCountdown: Int = WorkoutParameters.getReadySeconds

    // MARK: - Private State
    private let audio: AudioCueing
    private let now: () -> Date
    private var setStartTime: Date? = nil
    private var getReadyStartTime: Date? = nil
    private var restStartTime: Date? = nil
    private var lastBeepSecond: Int = -1
    private var timer: AnyCancellable? = nil

    // MARK: - Computed Properties

    var isComplete: Bool { roundsPhase == .complete }

    var session: WorkoutSession? { completedSession ?? partialSession }

    // MARK: - Initialization

    init(config: WorkoutConfig, audio: AudioCueing = AudioService.shared, now: @escaping () -> Date = Date.init) {
        self.config = config
        self.audio = audio
        self.now = now
    }

    // MARK: - Timer Control

    func start() {
        getReadyStartTime = now()
        LiveActivityService.shared.start(
            workoutType: config.workoutType.rawValue,
            totalTarget: config.targetRounds,
            mode: config.mode.rawValue,
            getReadySeconds: WorkoutParameters.getReadySeconds
        )
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

    // MARK: - Rounds Logic

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

    func setDone() {
        guard roundsPhase == .working, let start = setStartTime else { return }

        let setTime = now().timeIntervalSince(start)
        setTimes.append(setTime)

        if currentRound >= config.targetRounds {
            roundsPhase = .complete
            audio.playCompletionSound()
            stop()
            LiveActivityService.shared.end(
                phase: "complete", currentRound: currentRound,
                totalRounds: config.targetRounds, elapsedSeconds: totalElapsed,
                mode: config.mode.rawValue
            )
            createCompletedSession()
        } else {
            roundsPhase = .resting
            restCountdown = config.restDuration ?? 60
            restStartTime = now()
            lastBeepSecond = -1
            LiveActivityService.shared.update(
                phase: "resting", currentRound: currentRound,
                totalRounds: config.targetRounds, elapsedSeconds: totalElapsed,
                mode: config.mode.rawValue,
                countdownEndDate: Date().addingTimeInterval(TimeInterval(config.restDuration ?? 60))
            )
        }
    }

    func skipRest() {
        guard roundsPhase == .resting else { return }
        transitionToNextRound()
    }

    private func transitionToNextRound() {
        audio.playGoBeep()
        currentRound += 1
        roundsPhase = .working
        setStartTime = now()
        currentSetElapsed = 0
        lastBeepSecond = -1
        LiveActivityService.shared.update(
            phase: "active", currentRound: currentRound,
            totalRounds: config.targetRounds, elapsedSeconds: totalElapsed,
            mode: config.mode.rawValue,
            countdownEndDate: Date()
        )
    }

    // MARK: - Workout Completion

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
        LiveActivityService.shared.end(
            phase: "complete", currentRound: currentRound,
            totalRounds: config.targetRounds, elapsedSeconds: totalElapsed,
            mode: config.mode.rawValue
        )

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
