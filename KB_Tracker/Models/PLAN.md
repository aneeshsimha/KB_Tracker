# Models/ Folder Plan

## Purpose
Contains data models, enums, and configuration structs for the app.

## Current State
- `WorkoutSession.swift` - SwiftData model with enums embedded inline

## Target Files
| File | Status | Description |
|------|--------|-------------|
| `WorkoutSession.swift` | Refactor | SwiftData model for history (remove embedded enums) |
| `Enums.swift` | Create | All shared enums: KBType, WorkoutMode, TimerPhase, RoundsPhase |
| `WorkoutConfig.swift` | Create | Settings struct passed Home → Timer → Complete |

## Tasks

### 1. Create Enums.swift
- [ ] Extract `WorkoutMode` from WorkoutSession.swift
- [ ] Extract `KBType` from WorkoutSession.swift
- [ ] Move `TimerPhase` from EMOMTimerView.swift
- [ ] Move `RoundsPhase` from RoundsTimerView.swift
- [ ] Move `SystemSound` from AudioManager.swift

### 2. Refactor WorkoutSession.swift
- [ ] Remove `WorkoutMode` enum definition (import from Enums.swift)
- [ ] Remove `KBType` enum definition (import from Enums.swift)
- [ ] Keep SwiftData @Model class

### 3. Create WorkoutConfig.swift
- [ ] Create a lightweight struct for passing workout settings
- [ ] Not persisted - just used to pass config between views

## Implementation Notes

### Enums.swift
```swift
// Enums.swift

import Foundation

enum WorkoutMode: String, Codable {
    case emom      // Every Minute On the Minute
    case rounds    // Fixed rounds with rest intervals
}

enum KBType: String, Codable {
    case single    // Single kettlebell
    case double    // Double kettlebells (2x)
}

enum TimerPhase {
    case getReady
    case active
    case complete
}

enum RoundsPhase {
    case getReady    // 5-second countdown before start
    case working     // User is doing the set
    case resting     // Rest countdown between sets
    case complete    // Workout finished
}
```

### WorkoutConfig.swift
```swift
// WorkoutConfig.swift

import Foundation

struct WorkoutConfig {
    let mode: WorkoutMode
    let kettlebellType: KBType
    let weight: Int
    let targetRounds: Int
    let restDuration: Int?

    var weightDisplay: String {
        switch kettlebellType {
        case .single: return "\(weight)kg"
        case .double: return "2×\(weight)kg"
        }
    }
}
```

## Dependencies
- None (base layer)

## Testing
- Build should succeed with separated enums
- All views importing enums should compile
- WorkoutSession should still persist correctly
