# Services - MVP Milestones

## MVP Requirements
- `AudioService.swift` (renamed from AudioManager)

## Milestones

### Milestone 1: Rename AudioManager
- [ ] Move/rename `AudioManager.swift` → `AudioService.swift`
- [ ] Update class name to AudioService
- [ ] Keep all existing functionality

### Milestone 2: Update References
- [ ] Update all imports and references to AudioManager
- [ ] Update EMOMTimerView references
- [ ] Update RoundsTimerView references
- [ ] Verify audio still plays correctly

### Milestone 3: (Post-MVP) Add HapticsService
- [ ] Create `HapticsService.swift`
- [ ] Add haptic feedback for timer events
- [ ] Integrate with TimerViewModel

### Milestone 4: (Post-MVP) Add PersistenceService
- [ ] Create `PersistenceService.swift`
- [ ] Abstract SwiftData operations
- [ ] Centralize data persistence logic

## Verification
- [ ] App builds successfully
- [ ] Audio cues play at correct times
- [ ] No AudioManager references remain
