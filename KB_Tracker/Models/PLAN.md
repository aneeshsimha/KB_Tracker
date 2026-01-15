# Models Directory

This directory contains SwiftData models for persistent storage.

---

## Files

### WorkoutSession.swift

**Purpose:** The core data model representing a completed (or in-progress) workout

**Implementation:**

```swift
import Foundation
import SwiftData

enum WorkoutMode: String, Codable {
    case emom      // Every Minute On the Minute
    case rounds    // Fixed rounds with rest intervals
}

enum KBType: String, Codable {
    case single    // Single kettlebell
    case double    // Double kettlebells (2x)
}

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var mode: WorkoutMode = .emom
    var kettlebellType: KBType = .double
    var weight: Int = 20                        // Weight in kg (12-24)
    var targetRounds: Int = 20                  // EMOM: minutes, Rounds: target count
    var completedRounds: Int = 0
    var totalDuration: TimeInterval = 0         // Total workout time in seconds
    var restDuration: Int? = nil                // Rest between sets (rounds mode only)
    var setTimes: [TimeInterval] = []           // Completion time for each set
    var notes: String? = nil                    // User notes (failure, improvements)
    var isCompleted: Bool = false               // Was workout finished normally?

    init() {}

    // Convenience initializer for starting a new workout
    init(mode: WorkoutMode, kettlebellType: KBType, weight: Int, targetRounds: Int, restDuration: Int? = nil) {
        self.id = UUID()
        self.date = Date()
        self.mode = mode
        self.kettlebellType = kettlebellType
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
```

**Computed Properties to Add:**

```swift
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
}
```

---

## Weight Options

For the picker UI, these are the valid weight options:

```swift
// Single KB: 12, 14, 16, 18, 20, 22, 24 kg
let singleWeights = stride(from: 12, through: 24, by: 2).map { $0 }

// Double KB: Same weights (displayed as 2×12, 2×14, etc.)
let doubleWeights = stride(from: 12, through: 24, by: 2).map { $0 }
```

---

## SwiftData Setup

In `KB_TrackerApp.swift`, update the ModelContainer:

```swift
@main
struct KB_TrackerApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: WorkoutSession.self)
    }
}
```

---

## Dependencies

- SwiftData (Apple framework)
- Foundation

---

## Used By

- `HomeView` - Queries last workout for pre-filling
- `EMOMTimerView` - Creates/updates session during workout
- `RoundsTimerView` - Same
- `SummaryView` - Displays completed session stats
- `HistoryView` - Lists all sessions
- `HistoryDetailView` - Shows single session details

---

## Notes

- The `@Model` macro handles Codable conformance automatically
- `setTimes` array stores completion time for each round (index 0 = round 1)
- `restDuration` is only populated for rounds mode
- Delete the existing `Item.swift` file after implementing this
