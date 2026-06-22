// KBTimerAttributes.swift
// KB_TrackerWidget — mirrors the definition in the app target

import ActivityKit
import Foundation

struct KBTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: String           // "getReady" | "active" | "resting" | "complete"
        var currentRound: Int
        var totalRounds: Int
        var elapsedSeconds: TimeInterval
        var mode: String            // "emom" | "rounds"
    }

    var workoutType: String         // "abc" | "snatchTest" | "swingInterval" | "press"
    var totalTarget: Int            // minutes or rounds
}
