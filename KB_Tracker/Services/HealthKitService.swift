// HealthKitService.swift
// KB_Tracker

import Foundation
import HealthKit

@MainActor enum HealthKitService {
    private static let store = HKHealthStore()
    private static var exporting = Set<UUID>()

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    static func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        let writeTypes: Set<HKSampleType> = [HKObjectType.workoutType()]
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: [])
            return store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
        } catch {
            return false
        }
    }

    static func save(_ session: WorkoutSession) async -> Bool {
        if let exported = session.healthExportedAt, exported >= session.modifiedAt { return true }
        guard !exporting.contains(session.id) else { return false }
        guard session.totalDuration.isFinite, session.totalDuration > 0 else {
            session.healthExportError = "Add a workout duration before exporting."
            return false
        }
        exporting.insert(session.id)
        defer { exporting.remove(session.id) }
        guard await requestAuthorization() else {
            session.healthExportError = "Allow KB Tracker to write workouts in Apple Health, then retry."
            return false
        }
        let start = session.date
        let end = session.endedAt ?? start.addingTimeInterval(session.totalDuration + session.pausedDuration)
        guard end > start else { session.healthExportError = "The workout end must follow its start."; return false }

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
            session.healthWorkoutID = workout.uuid.uuidString
            session.healthExportedAt = Date()
            session.healthExportError = nil
            return true
        } catch {
            session.healthExportError = error.localizedDescription
            return false
        }
    }

    private static func metadata(for session: WorkoutSession) -> [String: Any] {
        var meta: [String: Any] = [
            HKMetadataKeyWorkoutBrandName: "KB Tracker",
            HKMetadataKeySyncIdentifier: "kb-session-\(session.id.uuidString)",
            HKMetadataKeySyncVersion: max(1, Int(session.modifiedAt.timeIntervalSince1970 * 1000)),
            "kbWorkoutType": session.workoutType.rawValue,
            "kbTitle": session.displayTitle,
            "kbCompleted": session.isCompleted,
            "kbMode": session.mode.rawValue,
            "kbType": session.kettlebellType.rawValue,
            "kbWeight": session.weight,
            "kbCompletedRounds": session.completedRounds,
        ]
        if let rest = session.restDuration {
            meta["kbRestDuration"] = rest
        }
        if let reps = session.recordedReps { meta["kbRecordedReps"] = reps }
        if let volume = session.recordedVolume { meta["kbVolumeKg"] = volume }
        return meta
    }
}
