# ViewModels/ Folder Plan

## Purpose
Contains the business logic layer, separating timer/state management from UI.

## Current State
- Timer logic is embedded directly in EMOMTimerView.swift and RoundsTimerView.swift
- No separate ViewModel layer exists

## Target Files
| File | Status | Description |
|------|--------|-------------|
| `TimerViewModel.swift` | Create | Core timer logic, phases, audio cues |
| `HistoryViewModel.swift` | Create | Fetch/filter past sessions |

## Tasks

### 1. Create TimerViewModel.swift
- [ ] Extract timer state from EMOMTimerView (currentRound, secondsIntoMinute, totalElapsed, etc.)
- [ ] Extract timer state from RoundsTimerView (phase, restCountdown, etc.)
- [ ] Move timer tick handlers (handleTimerTick, handleGetReadyPhase, etc.)
- [ ] Move workout completion logic
- [ ] Make it @Observable for SwiftUI

### 2. Create HistoryViewModel.swift
- [ ] Create filtering logic (by date range, mode, weight)
- [ ] Create sorting options
- [ ] Statistics calculations (weekly totals, averages)

## Implementation Notes

### TimerViewModel.swift
```swift
// TimerViewModel.swift

import Foundation
import Combine

@Observable
class TimerViewModel {
    // Configuration
    let config: WorkoutConfig

    // Timer state
    var currentRound: Int = 0
    var secondsIntoMinute: Double = 0
    var totalElapsed: TimeInterval = 0
    var setTimes: [TimeInterval] = []
    var phase: TimerPhase = .getReady
    var isSetInProgress: Bool = false

    // EMOM specific
    var getReadyCountdown: Int = 5

    // Rounds specific
    var restCountdown: Int = 0
    var roundsPhase: RoundsPhase = .getReady
    var currentSetElapsed: TimeInterval = 0

    // Private
    private var setStartTime: Date? = nil
    private var lastBeepSecond: Int = -1
    private var timer: Timer? = nil

    init(config: WorkoutConfig) {
        self.config = config
    }

    func startTimer() { ... }
    func stopTimer() { ... }
    func handleSetDone() { ... }
    func skipRest() { ... }

    // Creates WorkoutSession when complete
    func createSession() -> WorkoutSession { ... }
}
```

### HistoryViewModel.swift
```swift
// HistoryViewModel.swift

import Foundation
import SwiftData

@Observable
class HistoryViewModel {
    var filterMode: WorkoutMode? = nil
    var sortOrder: SortOrder = .dateDescending

    enum SortOrder {
        case dateDescending
        case dateAscending
        case roundsDescending
    }

    func filteredSessions(_ sessions: [WorkoutSession]) -> [WorkoutSession] { ... }
    func weeklyStats(_ sessions: [WorkoutSession]) -> WeeklyStats { ... }
}
```

## Dependencies
- Models/Enums.swift
- Models/WorkoutConfig.swift
- Services/AudioService.swift

## Testing
- Timer should count correctly in both EMOM and Rounds modes
- Phase transitions should happen at correct times
- Audio cues should play at right moments
- WorkoutSession should be created correctly on completion
