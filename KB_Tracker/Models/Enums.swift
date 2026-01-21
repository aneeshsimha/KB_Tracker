// Enums.swift
// KB_Tracker
//
// Consolidated enum definitions for workout tracking

import Foundation

/// Workout mode - determines timer behavior
enum WorkoutMode: String, Codable {
    case emom      // Every Minute On the Minute
    case rounds    // Fixed rounds with rest intervals
}

/// Kettlebell type - single or double
enum KBType: String, Codable {
    case single    // Single kettlebell
    case double    // Double kettlebells (2x)
}

/// Timer phase for EMOM mode
enum TimerPhase {
    case getReady   // 5-second countdown before start
    case active     // Workout in progress
    case complete   // Workout finished
}

/// Timer phase for Rounds mode
enum RoundsPhase {
    case getReady   // 5-second countdown before start
    case working    // User is doing the set
    case resting    // Rest countdown between sets
    case complete   // Workout finished
}
