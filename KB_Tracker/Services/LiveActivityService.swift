// LiveActivityService.swift
// KB_Tracker

import ActivityKit
import Foundation

@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()

    private var activity: Activity<KBTimerAttributes>?

    func start(workoutType: String, totalTarget: Int, mode: String, getReadySeconds: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = KBTimerAttributes.ContentState(
            phase: "getReady",
            currentRound: 0,
            totalRounds: totalTarget,
            elapsedSeconds: 0,
            mode: mode,
            countdownEndDate: Date().addingTimeInterval(TimeInterval(getReadySeconds))
        )
        let attrs = KBTimerAttributes(workoutType: workoutType, totalTarget: totalTarget)

        do {
            activity = try Activity<KBTimerAttributes>.request(
                attributes: attrs,
                content: .init(state: state, staleDate: nil)
            )
        } catch {
            // Live Activity unavailable (simulator, permissions denied, etc.)
        }
    }

    func update(phase: String, currentRound: Int, totalRounds: Int, elapsedSeconds: TimeInterval, mode: String, countdownEndDate: Date) {
        guard let activity else { return }
        let state = KBTimerAttributes.ContentState(
            phase: phase,
            currentRound: currentRound,
            totalRounds: totalRounds,
            elapsedSeconds: elapsedSeconds,
            mode: mode,
            countdownEndDate: countdownEndDate
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    func end(phase: String, currentRound: Int, totalRounds: Int, elapsedSeconds: TimeInterval, mode: String) {
        guard let activity else { return }
        let state = KBTimerAttributes.ContentState(
            phase: phase,
            currentRound: currentRound,
            totalRounds: totalRounds,
            elapsedSeconds: elapsedSeconds,
            mode: mode,
            countdownEndDate: Date()
        )
        Task {
            await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .default)
            self.activity = nil
        }
    }
}
