# Views/ Folder Plan

## Purpose
Contains SwiftUI views - pure UI layer that delegates logic to ViewModels.

## Current State
| File | Status |
|------|--------|
| `HomeView.swift` | Keep (minor updates) |
| `EMOMTimerView.swift` | Refactor (move logic to ViewModel) |
| `RoundsTimerView.swift` | Refactor (move logic to ViewModel) |
| `SummaryView.swift` | Rename to WorkoutCompleteView |
| `HistoryView.swift` | Keep (minor updates) |
| `HistoryDetailView.swift` | Keep |

## Target Files
| File | Status | Description |
|------|--------|-------------|
| `HomeView.swift` | Update | Setup screen - uses WorkoutConfig |
| `EMOMTimerView.swift` | Simplify | UI only, delegates to TimerViewModel |
| `RoundsTimerView.swift` | Simplify | UI only, delegates to TimerViewModel |
| `WorkoutCompleteView.swift` | Rename | Renamed from SummaryView |
| `HistoryView.swift` | Update | Uses HistoryViewModel for filtering |
| `HistoryDetailView.swift` | Keep | Minimal changes |

## Tasks

### 1. Simplify EMOMTimerView.swift
- [ ] Remove all timer state variables
- [ ] Remove handleTimerTick, handleGetReadyPhase, handleActivePhase
- [ ] Remove handleSetDone, completeWorkout logic
- [ ] Add `@State private var viewModel: TimerViewModel`
- [ ] Bind UI to viewModel properties

### 2. Simplify RoundsTimerView.swift
- [ ] Remove all timer state variables
- [ ] Remove handleTimerTick, handleWorkingPhase, handleRestingPhase
- [ ] Remove setDone, transitionToNextRound logic
- [ ] Add `@State private var viewModel: TimerViewModel`
- [ ] Bind UI to viewModel properties

### 3. Rename SummaryView → WorkoutCompleteView
- [ ] Rename file
- [ ] Rename struct
- [ ] Update all references

### 4. Update HomeView.swift
- [ ] Create WorkoutConfig and pass to timer views
- [ ] Minor cleanup

### 5. Update HistoryView.swift
- [ ] Add HistoryViewModel for filtering (optional enhancement)

## Implementation Notes

### Simplified EMOMTimerView
```swift
struct EMOMTimerView: View {
    let config: WorkoutConfig

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: TimerViewModel
    @State private var showExitConfirmation = false
    @State private var navigateToSummary = false

    init(config: WorkoutConfig) {
        self.config = config
        _viewModel = State(initialValue: TimerViewModel(config: config))
    }

    var body: some View {
        // Pure UI - binds to viewModel.phase, viewModel.currentRound, etc.
    }
}
```

## Dependencies
- ViewModels/TimerViewModel.swift
- ViewModels/HistoryViewModel.swift
- Models/WorkoutConfig.swift
- Components/* (WeightPicker, DurationPicker, TimerDisplay)

## Testing
- All screens should render correctly
- Navigation flow should work
- Timer UI should update from ViewModel
