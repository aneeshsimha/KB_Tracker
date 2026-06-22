// Enums.swift
// KB_Tracker
//
// Consolidated enum definitions for the app

import Foundation

// MARK: - Workout Configuration Enums

/// The workout mode type
enum WorkoutMode: String, Codable {
    case emom      // Every Minute On the Minute
    case rounds    // Fixed rounds with rest intervals
}

/// Kettlebell type (single or double)
enum KBType: String, Codable {
    case single    // Single kettlebell
    case double    // Double kettlebells (2x)
}

/// Which workout this session is: the ABC complex or the press ladder.
enum WorkoutType: String, Codable {
    case abc           // 2 cleans · 1 press · 3 front squats (EMOM/Rounds)
    case press         // 2-3-5-10 press ladder
    case snatchTest    // timed snatch test (EMOM-style)
    case swingInterval // swing intervals with rest (Rounds-style)
}

// MARK: - Timer Phase Enums

/// Phase states for EMOM timer
enum TimerPhase {
    case getReady   // 5-second countdown before start
    case active     // Active workout
    case complete   // Workout finished
}

/// Phase states for Rounds timer
enum RoundsPhase {
    case getReady   // 5-second countdown before start
    case working    // User is doing the set
    case resting    // Rest countdown between sets
    case complete   // Workout finished
}
