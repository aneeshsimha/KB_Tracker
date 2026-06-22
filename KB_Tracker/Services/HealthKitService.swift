// HealthKitService.swift
// KB_Tracker

import Foundation
import HealthKit

enum HealthKitService {
    private static let store = HKHealthStore()

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    static func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        let writeTypes: Set<HKSampleType> = [HKObjectType.workoutType()]
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: [])
            return true
        } catch {
            return false
        }
    }

    static func save(_ session: WorkoutSession) async -> Bool {
        guard isAvailable else { return false }
        guard await requestAuthorization() else { return false }

        let start = session.date
        let end = start.addingTimeInterval(session.totalDuration)

        let workout = HKWorkout(
            activityType: .functionalStrengthTraining,
            start: start,
            end: end,
            duration: session.totalDuration,
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: metadata(for: session)
        )

        do {
            try await store.save(workout)
            return true
        } catch {
            return false
        }
    }

    private static func metadata(for session: WorkoutSession) -> [String: Any] {
        var meta: [String: Any] = [
            HKMetadataKeyWorkoutBrandName: "KB Tracker",
            "kbMode": session.mode.rawValue,
            "kbType": session.kettlebellType.rawValue,
            "kbWeight": session.weight,
            "kbCompletedRounds": session.completedRounds,
        ]
        if let rest = session.restDuration {
            meta["kbRestDuration"] = rest
        }
        return meta
    }
}
