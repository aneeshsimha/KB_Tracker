// WorkoutConfig.swift
// KB_Tracker
//
// Configuration struct for passing workout settings between views

import Foundation

/// A struct that encapsulates all workout configuration settings
struct WorkoutConfig {
    let workoutType: WorkoutType
    let mode: WorkoutMode            // meaningful for .abc only
    let kettlebellType: KBType
    let weight: Int
    let targetRounds: Int            // ABC EMOM: minutes; ABC Rounds: round count
    let restDuration: Int?           // ABC Rounds only
    let targetLadders: Int           // press only

    static func emom(kettlebellType: KBType, weight: Int, minutes: Int) -> WorkoutConfig {
        WorkoutConfig(workoutType: .abc, mode: .emom, kettlebellType: kettlebellType,
                      weight: weight, targetRounds: minutes, restDuration: nil, targetLadders: 0)
    }

    static func rounds(kettlebellType: KBType, weight: Int, rounds: Int, restSeconds: Int) -> WorkoutConfig {
        WorkoutConfig(workoutType: .abc, mode: .rounds, kettlebellType: kettlebellType,
                      weight: weight, targetRounds: rounds, restDuration: restSeconds, targetLadders: 0)
    }

    static func press(kettlebellType: KBType, weight: Int, targetLadders: Int) -> WorkoutConfig {
        WorkoutConfig(workoutType: .press, mode: .emom, kettlebellType: kettlebellType,
                      weight: weight, targetRounds: 0, restDuration: nil, targetLadders: targetLadders)
    }

    static func snatchTest(kettlebellType: KBType, weight: Int, minutes: Int) -> WorkoutConfig {
        WorkoutConfig(workoutType: .snatchTest, mode: .emom, kettlebellType: kettlebellType,
                      weight: weight, targetRounds: minutes, restDuration: nil, targetLadders: 0)
    }

    static func swingInterval(kettlebellType: KBType, weight: Int, rounds: Int, restSeconds: Int) -> WorkoutConfig {
        WorkoutConfig(workoutType: .swingInterval, mode: .rounds, kettlebellType: kettlebellType,
                      weight: weight, targetRounds: rounds, restDuration: restSeconds, targetLadders: 0)
    }

    var weightDisplay: String {
        switch kettlebellType {
        case .single: return "\(weight)kg"
        case .double: return "2×\(weight)kg"
        }
    }

    // EMOM-only semantic accessor — targetRounds stores minutes for EMOM configs.
    var targetMinutes: Int { targetRounds }
}
