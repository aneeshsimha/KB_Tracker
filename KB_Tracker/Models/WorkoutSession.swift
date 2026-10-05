// WorkoutSession.swift
// KB_Tracker
//
// Core data model for workout sessions
// Note: WorkoutMode and KBType enums are defined in Enums.swift

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var date: Date = Date()
    private var modeRaw: String = WorkoutMode.emom.rawValue
    private var kettlebellTypeRaw: String = KBType.double.rawValue
    var weight: Int = 20                        // Weight in kg (12-24)
    // Storage: EMOM sessions store the minute count here; Rounds sessions store the round count.
    // Use targetMinutes for EMOM duration reads (see computed accessor below).
    var targetRounds: Int = 20
    var completedRounds: Int = 0
    var totalDuration: TimeInterval = 0         // Total workout time in seconds
    var restDuration: Int? = nil                // Rest between sets (rounds mode only)
    var setTimes: [TimeInterval] = []           // Completion time for each set
    var notes: String? = nil                    // User notes (failure, improvements)
    var isCompleted: Bool = false               // Was workout finished normally?
    private var workoutTypeRaw: String = WorkoutType.abc.rawValue
    var targetLadders: Int = 0          // press: target number of 2-3-5-10 ladders
    var ladderReps: [Int] = []          // press: reps completed per ladder (full = 20)
    var schemaVersion: Int = 1
    var definitionData: Data? = nil
    var resultsData: Data? = nil
    var endedAt: Date? = nil
    var pausedDuration: TimeInterval = 0
    var sourceRaw: String = "legacy"
    var difficultyRaw: String? = nil
    var programID: UUID? = nil
    var modifiedAt: Date = Date()
    var healthExportedAt: Date? = nil
    var healthWorkoutID: String? = nil
    var healthExportError: String? = nil

    var mode: WorkoutMode {
        get { WorkoutMode(rawValue: modeRaw) ?? .emom }
        set { modeRaw = newValue.rawValue }
    }

    var kettlebellType: KBType {
        get { KBType(rawValue: kettlebellTypeRaw) ?? .double }
        set { kettlebellTypeRaw = newValue.rawValue }
    }

    var workoutType: WorkoutType {
        get { WorkoutType(rawValue: workoutTypeRaw) ?? .abc }
        set { workoutTypeRaw = newValue.rawValue }
    }

    init() {}

    // Convenience initializer for starting a new workout
    init(mode: WorkoutMode, kettlebellType: KBType, weight: Int, targetRounds: Int, restDuration: Int? = nil) {
        self.modeRaw = mode.rawValue
        self.kettlebellTypeRaw = kettlebellType.rawValue
        self.weight = weight
        self.targetRounds = targetRounds
        self.restDuration = restDuration
    }
}

// MARK: - Computed Properties
extension WorkoutSession {
    var definition: WorkoutDefinition? {
        get { definitionData.flatMap { try? JSONDecoder().decode(WorkoutDefinition.self, from: $0) } }
        set { definitionData = newValue.flatMap { try? JSONEncoder().encode($0) } }
    }
    var results: [WorkoutSetResult] {
        get { resultsData.flatMap { try? JSONDecoder().decode([WorkoutSetResult].self, from: $0) } ?? [] }
        set { resultsData = try? JSONEncoder().encode(newValue) }
    }
    var difficulty: SessionDifficulty? {
        get { difficultyRaw.flatMap(SessionDifficulty.init(rawValue:)) }
        set { difficultyRaw = newValue?.rawValue }
    }
    var displayTitle: String { definition?.name ?? workoutType.title }
    var recordedReps: Int? {
        if resultsData != nil {
            let completed = results.filter(\.completed)
            guard !completed.isEmpty else { return nil }
            // A runner set is only aggregate-safe when every prescribed movement
            // in its block has an actual rep entry. Manual blocks have no
            // prescription, so their explicitly entered movements remain valid.
            let blocks = Dictionary(uniqueKeysWithValues: (definition?.blocks ?? []).map { ($0.id, $0) })
            guard completed.allSatisfy({ result in
                guard result.totalReps != nil else { return false }
                guard session.sourceRaw != "manual", let block = blocks[result.blockID], !block.movements.isEmpty else { return true }
                let recorded = Set(result.repetitions.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
                let prescribed = Set(block.movements.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
                return prescribed.isSubset(of: recorded)
            }) else { return nil }
            return completed.reduce(0) { $0 + ($1.totalReps ?? 0) }
        }
        return workoutType == .press ? ladderReps.reduce(0, +) : nil
    }
    var estimatedReps: Int? {
        if let recordedReps { return recordedReps }
        return workoutType == .abc ? setTimes.count * 6 : nil
    }
    var recordedVolume: Double? {
        guard resultsData != nil, recordedReps != nil else { return nil }
        return results.filter(\.completed).reduce(0) { $0 + Double($1.totalReps ?? 0) * $1.loadKg * Double($1.bells) }
    }
    var workSets: Int { resultsData != nil ? results.filter(\.completed).count : (workoutType == .press ? ladderReps.count : setTimes.count) }
    var repeatDefinition: WorkoutDefinition {
        definition ?? .builtIn(WorkoutConfig(workoutType: workoutType, mode: mode, kettlebellType: kettlebellType, weight: weight, targetRounds: max(1, targetRounds), restDuration: restDuration, targetLadders: max(1, targetLadders)))
    }
    // Display string for weight (e.g., "2×20kg" or "20kg")
    var weightDisplay: String { kettlebellType.weightDisplay(weight) }

    // Average set completion time
    var averageSetTime: TimeInterval? {
        guard !setTimes.isEmpty else { return nil }
        return setTimes.reduce(0, +) / Double(setTimes.count)
    }

    // EMOM-only semantic accessor — wraps targetRounds for clarity at call sites.
    // Do not use for Rounds sessions.
    var targetMinutes: Int {
        get { targetRounds }
        set { targetRounds = newValue }
    }

    // Press: total reps across all ladders (including a trailing partial).
    var totalReps: Int { ladderReps.reduce(0, +) }

    // Press: number of fully-completed ladders (20 reps each).
    var completedLadders: Int { ladderReps.filter { $0 == 20 }.count }
}
