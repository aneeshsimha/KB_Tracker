# ViewModels - MVP Milestones

## MVP Requirements
- `TimerViewModel.swift` handling both EMOM and Rounds modes

## Milestones

### Milestone 1: Create TimerViewModel
- [ ] Create `TimerViewModel.swift`
- [ ] Add WorkoutConfig property
- [ ] Add timer state properties (isRunning, isPaused, etc.)
- [ ] Implement timer logic (start, pause, resume, stop)
- [ ] Add phase management for EMOM/Rounds modes

### Milestone 2: Integrate with EMOMTimerView
- [ ] Refactor EMOMTimerView to use TimerViewModel
- [ ] Remove duplicated timer logic from view
- [ ] Verify EMOM functionality works correctly

### Milestone 3: Integrate with RoundsTimerView
- [ ] Refactor RoundsTimerView to use TimerViewModel
- [ ] Remove duplicated timer logic from view
- [ ] Verify Rounds functionality works correctly

### Milestone 4: (Post-MVP) HistoryViewModel
- [ ] Create HistoryViewModel for filtering workout history
- [ ] Add date range filtering
- [ ] Add workout type filtering

## Verification
- [ ] App builds successfully
- [ ] Timer starts/pauses/resumes correctly
- [ ] Phase transitions work for both modes
- [ ] Audio cues trigger at correct times
