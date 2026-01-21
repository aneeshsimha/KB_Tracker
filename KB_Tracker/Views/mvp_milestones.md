# Views - MVP Milestones

## MVP Requirements
- Simplified EMOMTimerView using TimerViewModel
- Simplified RoundsTimerView using TimerViewModel
- Rename SummaryView → WorkoutCompleteView

## Milestones

### Milestone 1: Update HomeView
- [ ] Update HomeView to use WorkoutConfig
- [ ] Pass WorkoutConfig to timer views instead of individual parameters

### Milestone 2: Refactor EMOMTimerView
- [ ] Integrate TimerViewModel
- [ ] Remove inline timer logic
- [ ] Simplify view to focus on UI only
- [ ] Maintain all current functionality

### Milestone 3: Refactor RoundsTimerView
- [ ] Integrate TimerViewModel
- [ ] Remove inline timer logic
- [ ] Simplify view to focus on UI only
- [ ] Maintain all current functionality

### Milestone 4: Rename SummaryView
- [ ] Rename `SummaryView.swift` → `WorkoutCompleteView.swift`
- [ ] Update all references to SummaryView
- [ ] Verify navigation still works correctly

## Verification
- [ ] App builds successfully
- [ ] All previews render correctly
- [ ] Timer functionality unchanged
- [ ] Navigation flow works end-to-end
