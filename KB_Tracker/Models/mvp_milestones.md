# Models - MVP Milestones

## MVP Requirements
- `Enums.swift` with WorkoutMode, KBType, TimerPhase, RoundsPhase
- `WorkoutConfig.swift` struct for passing settings between views

## Milestones

### Milestone 1: Extract Enums ✅
- [ ] Create `Enums.swift`
- [ ] Move/consolidate WorkoutMode enum
- [ ] Move/consolidate KBType enum
- [ ] Add TimerPhase enum
- [ ] Add RoundsPhase enum

### Milestone 2: Create WorkoutConfig
- [ ] Create `WorkoutConfig.swift`
- [ ] Define WorkoutConfig struct with all workout settings
- [ ] Add convenience initializers if needed

### Milestone 3: Update Imports
- [ ] Update `WorkoutSession.swift` to use new enums
- [ ] Verify all model references are correct

## Verification
- [ ] App builds successfully
- [ ] No duplicate enum definitions
- [ ] All views can access enums correctly
