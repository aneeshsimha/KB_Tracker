// LiveActivityService.swift
// KB_Tracker

import ActivityKit
import Foundation

@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()

    private var activity: Activity<KBTimerAttributes>?
    private var updateTask: Task<Void, Never>?

    func reconcile(hasActiveWorkout: Bool) {
        if hasActiveWorkout {
            activity = activity ?? Activity<KBTimerAttributes>.activities.first
        } else {
            updateTask?.cancel()
            activity = nil
            for stale in Activity<KBTimerAttributes>.activities {
                Task { await stale.end(nil, dismissalPolicy: .immediate) }
            }
        }
    }

    func start(workoutType: String, totalTarget: Int, mode: String, getReadySeconds: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        reconcile(hasActiveWorkout: false)

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
        activity = activity ?? Activity<KBTimerAttributes>.activities.first
        guard let activity else { return }
        let state = KBTimerAttributes.ContentState(
            phase: phase,
            currentRound: currentRound,
            totalRounds: totalRounds,
            elapsedSeconds: elapsedSeconds,
            mode: mode,
            countdownEndDate: countdownEndDate
        )
        updateTask?.cancel()
        updateTask = Task {
            guard !Task.isCancelled else { return }
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    func end(currentRound: Int, totalRounds: Int, elapsedSeconds: TimeInterval, mode: String) {
        updateTask?.cancel()
        guard let activity = activity ?? Activity<KBTimerAttributes>.activities.first else { return }
        self.activity = nil
        let state = KBTimerAttributes.ContentState(
            phase: "complete",
            currentRound: currentRound,
            totalRounds: totalRounds,
            elapsedSeconds: elapsedSeconds,
            mode: mode,
            countdownEndDate: Date()
        )
        Task {
            await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .default)
        }
    }
}
