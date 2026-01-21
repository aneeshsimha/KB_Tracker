// WorkoutConfig.swift
// KB_Tracker
//
// Configuration struct for passing workout settings between views

import Foundation

/// Configuration struct for workout settings
struct WorkoutConfig {
    let mode: WorkoutMode
    let kettlebellType: KBType
    let weight: Int
    let targetRounds: Int       // EMOM: minutes, Rounds: target count
    let restDuration: Int?      // Only used in Rounds mode

    /// Display string for weight (e.g., "2×20kg" or "20kg")
    var weightDisplay: String {
        switch kettlebellType {
        case .single:
            return "\(weight)kg"
        case .double:
            return "2×\(weight)kg"
        }
    }

    /// Create config for EMOM mode
    static func emom(kettlebellType: KBType, weight: Int, minutes: Int) -> WorkoutConfig {
        WorkoutConfig(
            mode: .emom,
            kettlebellType: kettlebellType,
            weight: weight,
            targetRounds: minutes,
            restDuration: nil
        )
    }

    /// Create config for Rounds mode
    static func rounds(kettlebellType: KBType, weight: Int, rounds: Int, restDuration: Int) -> WorkoutConfig {
        WorkoutConfig(
            mode: .rounds,
            kettlebellType: kettlebellType,
            weight: weight,
            targetRounds: rounds,
            restDuration: restDuration
        )
    }
}
