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
    var targetRounds: Int = 20                  // EMOM: minutes, Rounds: target count
    var completedRounds: Int = 0
    var totalDuration: TimeInterval = 0         // Total workout time in seconds
    var restDuration: Int? = nil                // Rest between sets (rounds mode only)
    var setTimes: [TimeInterval] = []           // Completion time for each set
    var notes: String? = nil                    // User notes (failure, improvements)
    var isCompleted: Bool = false               // Was workout finished normally?
    private var workoutTypeRaw: String = WorkoutType.abc.rawValue
    var targetLadders: Int = 0          // press: target number of 2-3-5-10 ladders
    var ladderReps: [Int] = []          // press: reps completed per ladder (full = 20)

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
        self.id = UUID()
        self.date = Date()
        self.modeRaw = mode.rawValue
        self.kettlebellTypeRaw = kettlebellType.rawValue
        self.weight = weight
        self.targetRounds = targetRounds
        self.restDuration = restDuration
        self.completedRounds = 0
        self.totalDuration = 0
        self.setTimes = []
        self.notes = nil
        self.isCompleted = false
    }
}

// MARK: - Computed Properties
extension WorkoutSession {
    // Display string for weight (e.g., "2×20kg" or "20kg")
    var weightDisplay: String {
        switch kettlebellType {
        case .single:
            return "\(weight)kg"
        case .double:
            return "2×\(weight)kg"
        }
    }

    // Average set completion time
    var averageSetTime: TimeInterval? {
        guard !setTimes.isEmpty else { return nil }
        return setTimes.reduce(0, +) / Double(setTimes.count)
    }

    // Did any set go overtime (>60 seconds for EMOM)?
    var hasOvertimeSets: Bool {
        guard mode == .emom else { return false }
        return setTimes.contains { $0 > 60 }
    }

    // Rounds display string (e.g., "18/20")
    var roundsDisplay: String {
        "\(completedRounds)/\(targetRounds)"
    }

    // Press: total reps across all ladders (including a trailing partial).
    var totalReps: Int { ladderReps.reduce(0, +) }

    // Press: number of fully-completed ladders (20 reps each).
    var completedLadders: Int { ladderReps.filter { $0 == 20 }.count }
}
