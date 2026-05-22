// PressLadderViewModel.swift
// KB_Tracker
//
// State machine for the 2-3-5-10 press ladder. Pure logic + a stopwatch;
// no audio side-effects (the view plays cues via onChange).

import Foundation
import Combine

@MainActor
final class PressLadderViewModel: ObservableObject {
    /// Fixed rung sizes for one ladder.
    static let rungs = [2, 3, 5, 10]

    let config: WorkoutConfig

    @Published private(set) var currentLadder = 1        // 1-indexed
    @Published private(set) var currentRungIndex = 0     // 0..<rungs.count
    @Published private(set) var ladderReps: [Int] = []   // completed ladders (full = 20)
    @Published private(set) var currentLadderReps = 0    // reps in the in-progress ladder
    @Published private(set) var totalElapsed: TimeInterval = 0
    @Published private(set) var isComplete = false
    @Published private(set) var completedSession: WorkoutSession?
    @Published private(set) var partialSession: WorkoutSession?

    private var startDate: Date?
    private var timer: AnyCancellable?

    var targetLadders: Int { config.targetLadders }
    var currentRungReps: Int { Self.rungs[currentRungIndex] }
    var totalReps: Int { ladderReps.reduce(0, +) + currentLadderReps }
    var session: WorkoutSession? { completedSession ?? partialSession }

    init(config: WorkoutConfig) { self.config = config }

    func start() {
        startDate = Date()
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.startDate else { return }
                self.totalElapsed = Date().timeIntervalSince(start)
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    /// Log the current rung's reps and advance. Completes a ladder after rung 10.
    func logRung() {
        guard !isComplete else { return }
        currentLadderReps += Self.rungs[currentRungIndex]

        if currentRungIndex < Self.rungs.count - 1 {
            currentRungIndex += 1
        } else {
            // Ladder finished.
            ladderReps.append(currentLadderReps)
            currentLadderReps = 0
            currentRungIndex = 0
            if currentLadder >= targetLadders {
                finish(completed: true)
            } else {
                currentLadder += 1
            }
        }
    }

    /// Reverse the last `logRung()` — guards against mis-taps.
    func undoLastRung() {
        guard !isComplete else { return }
        if currentRungIndex > 0 {
            currentRungIndex -= 1
            currentLadderReps -= Self.rungs[currentRungIndex]
        } else if !ladderReps.isEmpty {
            // Step back into the previous ladder's final rung (the "10").
            ladderReps.removeLast()
            currentLadder -= 1
            currentRungIndex = Self.rungs.count - 1
            currentLadderReps = Self.rungs.dropLast().reduce(0, +) // 2+3+5 = 10
        }
    }

    func endEarly() { finish(completed: false) }

    private func finish(completed: Bool) {
        stop()
        var reps = ladderReps
        if currentLadderReps > 0 { reps.append(currentLadderReps) }

        let s = WorkoutSession()
        s.workoutType = .press
        s.kettlebellType = config.kettlebellType
        s.weight = config.weight
        s.targetLadders = config.targetLadders
        s.ladderReps = reps
        s.totalDuration = totalElapsed
        s.isCompleted = completed

        if completed {
            completedSession = s
            isComplete = true
        } else {
            partialSession = s
        }
    }
}
