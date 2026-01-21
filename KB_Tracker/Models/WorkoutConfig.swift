// WorkoutConfig.swift
// KB_Tracker
//
// Configuration struct for passing workout settings between views

import Foundation

/// A struct that encapsulates all workout configuration settings
struct WorkoutConfig {
    let mode: WorkoutMode
    let kettlebellType: KBType
    let weight: Int
    let targetRounds: Int       // For EMOM: minutes, for Rounds: round count
    let restDuration: Int?      // Rest between sets (rounds mode only)

    // MARK: - Convenience Initializers

    /// Create an EMOM workout configuration
    static func emom(kettlebellType: KBType, weight: Int, minutes: Int) -> WorkoutConfig {
        WorkoutConfig(
            mode: .emom,
            kettlebellType: kettlebellType,
            weight: weight,
            targetRounds: minutes,
            restDuration: nil
        )
    }

    /// Create a Rounds workout configuration
    static func rounds(kettlebellType: KBType, weight: Int, rounds: Int, restSeconds: Int) -> WorkoutConfig {
        WorkoutConfig(
            mode: .rounds,
            kettlebellType: kettlebellType,
            weight: weight,
            targetRounds: rounds,
            restDuration: restSeconds
        )
    }

    // MARK: - Computed Properties

    /// Display string for weight (e.g., "2×20kg" or "20kg")
    var weightDisplay: String {
        switch kettlebellType {
        case .single:
            return "\(weight)kg"
        case .double:
            return "2×\(weight)kg"
        }
    }
}
