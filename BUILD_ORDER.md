# Build Order - Armor Building Complex Tracker

Follow this sequence to implement the MVP. Each phase builds on the previous one.

---

## Progress Overview

| Phase | Status | Description |
|-------|--------|-------------|
| 1 | ✅ Complete | Foundation (Design System) |
| 2 | ✅ Complete | Core Timer Logic (Components) |
| 3 | ✅ Complete | Navigation & Home |
| 4 | ✅ Complete | EMOM Timer |
| 5 | ✅ Complete | Summary & Persistence |
| 6 | ⏳ Pending | History View |
| 7 | ⏳ Pending | Rounds Timer |
| 8 | ⏳ Pending | Polish & Edge Cases |

---

## Phase 1: Foundation (Design System) ✅ COMPLETE

### Design/Colors.swift ✅
- Implement hex color initializer
- Define AppColors struct with all color constants
- Ref: `Design/PLAN.md`

### Design/Typography.swift ✅
- Define font sizes and weights
- Create AppTypography struct with all text styles
- Ref: `Design/PLAN.md`

### Models/WorkoutSession.swift ✅
- Define enums: WorkoutMode, KBType
- Implement @Model class with all properties
- Add computed properties (weightDisplay, averageSetTime, etc.)
- Ref: `Models/PLAN.md`

### KB_TrackerApp.swift ✅
- Update ModelContainer to use WorkoutSession instead of Item
- Added NavigationStack wrapper
- Ref: `Models/PLAN.md`

### Deleted Files ✅
- `Item.swift` - removed
- `ContentView.swift` - replaced with HomeView

---

## Phase 2: Core Timer Logic ✅ COMPLETE

### Components/TimerDisplay.swift ✅
- Reusable timer display with large monospaced digits
- Supports overtime coloring (red warning)
- Optional label for round counter
- Convenience init with default parameters

### Components/WeightPicker.swift ✅
- Single/Double kettlebell type picker
- Weight selection (12-24kg in 2kg increments)
- Menu-style pickers

### Components/DurationPicker.swift ✅
- Mode-aware picker (EMOM vs Rounds)
- EMOM: minutes picker (10-30)
- Rounds: target rounds + rest duration pickers

### Utilities/AudioManager.swift ✅
- Singleton pattern for audio playback
- System sounds for countdown beeps, go beeps, completion
- Configured to play in silent mode

---

## Phase 3: Navigation & Home ✅ COMPLETE

### Views/HomeView.swift ✅
- Displays last workout card (from SwiftData query)
- Mode toggle (EMOM vs Rounds segmented control)
- WeightPicker component integration
- DurationPicker component integration
- START button navigates to timer views
- History link navigation
- Pre-fills settings from last completed workout

---

## Phase 4: EMOM Timer ✅ COMPLETE

### Views/EMOMTimerView.swift ✅
- TimerPhase enum (getReady, active, complete)
- 5-second GET READY countdown with audio beeps
- Minute-based countdown (60s → 0s) per round
- SET DONE button logs set completion time
- Overtime handling (negative time, red warning styling)
- Audio cues: warning beeps at :55-59, GO beep at :00
- Exit confirmation dialog
- Auto-navigation to SummaryView on completion

---

## Phase 5: Summary & Persistence ✅ COMPLETE

### Views/SummaryView.swift ✅
- Displays completed workout stats
- Rounds completed vs target
- Total time, average set time, weight
- Expandable set breakdown with overtime warnings
- Notes text input (multiline)
- SAVE button persists to SwiftData and dismisses

---

## Phase 6: History View ⏳ PENDING

### Views/HistoryView.swift
- Query all WorkoutSession from database (sorted by date, reverse)
- List view showing:
  - Date
  - Weight display (e.g., "2×20kg")
  - Rounds display (e.g., "18/20")
  - Mode (EMOM or Rounds)
  - Note preview (if exists)
- Tap to navigate to HistoryDetailView
- Ref: `Views/PLAN.md`
- **Effort:** 20 min
- **Blockers:** None (all dependencies complete)

### Views/HistoryDetailView.swift
- Receive single WorkoutSession
- Display all stats (same as SummaryView)
- Show full set breakdown
- Show notes
- Optional: Edit notes + save back to database
- Back button to return to HistoryView
- Ref: `Views/PLAN.md`
- **Effort:** 15 min

---

## Phase 7: Rounds Timer ⏳ PENDING

### Views/RoundsTimerView.swift
- Similar to EMOMTimerView but different timer logic:
  - 5-second GET READY countdown
  - WORKING phase: do the set (no countdown shown)
  - "SET DONE" → transition to RESTING
  - RESTING phase: countdown from restDuration to 0
  - At :05 and :00 → warning + go beeps
  - Repeat WORKING/RESTING until targetRounds completed
- Display: rest countdown, current round, elapsed time, last set time
- Ref: `Views/PLAN.md`
- **Effort:** 45 min
- **Blockers:** None (can reuse TimerPhase enum and patterns from EMOM)

---

## Phase 8: Polish & Edge Cases ⏳ PENDING

### Navigation Integration
- Wire up all NavigationStack / NavigationLink paths
- Ensure back buttons work correctly
- Test transitions between screens
- **Effort:** 15 min

### App-Level Configuration
- Update KB_TrackerApp.swift navigation structure if needed
- Add #Preview blocks to all views
- **Effort:** 10 min

### Edge Case Testing
- Exit mid-workout on EMOM (discard partial)
- Exit mid-workout on Rounds (discard partial)
- App backgrounding during workout (timer continues?)
- Switch modes mid-configuration
- Empty history (app just installed)
- **Effort:** 20 min

### Visual Polish
- Verify colors match dark tactical aesthetic
- Check spacing and alignment
- Ensure text contrast is high enough
- Test in light/dark mode (probably only dark)
- **Effort:** 15 min

---

## Summary Table

| Phase | File(s) | Status | Effort |
|-------|---------|--------|--------|
| 1 | Design/ + Models/ | ✅ Done | 50 min |
| 2 | Components/ + Utilities/ | ✅ Done | 70 min |
| 3 | HomeView | ✅ Done | 30 min |
| 4 | EMOMTimerView | ✅ Done | 90 min |
| 5 | SummaryView | ✅ Done | 25 min |
| 6 | HistoryView + HistoryDetailView | ⏳ Pending | 35 min |
| 7 | RoundsTimerView | ⏳ Pending | 45 min |
| 8 | Polish & Testing | ⏳ Pending | 60 min |

**Completed: ~265 minutes (~4.4 hours)**
**Remaining: ~140 minutes (~2.3 hours)**
**Total: ~405 minutes (~6.75 hours)**

---

## Testing Checklist

### After Phase 1 ✅
- [x] Colors are defined and accessible
- [x] Typography is defined and accessible
- [x] WorkoutSession compiles and has all properties
- [x] App launches without errors

### After Phase 3 ✅
- [x] HomeView displays with no data (empty state)
- [x] Mode toggle switches between EMOM/Rounds
- [x] Weight picker has correct options
- [x] Duration picker shows correct fields for mode
- [x] START button is tappable (doesn't crash)

### After Phase 4 ✅
- [x] EMOM timer starts with 5-second countdown
- [x] Beep plays at :00
- [x] SET DONE button logs completion time
- [x] Timer continues to next minute
- [x] Workout ends after targetMinutes
- [x] Can exit mid-workout

### After Phase 5 ✅
- [x] Summary shows all stats correctly
- [x] Can add notes
- [x] SAVE persists workout to database
- [x] No crashes

### After Phase 6
- [ ] HistoryView lists all completed workouts
- [ ] Last workout pre-fills HomeView
- [ ] Tap history item shows details
- [ ] Can see set breakdown and notes

### After Phase 7
- [ ] Rounds timer counts up sets
- [ ] Rest countdown works
- [ ] Beeps at correct times
- [ ] Completes after targetRounds

### After Phase 8
- [ ] All transitions are smooth
- [ ] No UI glitches
- [ ] All text is readable
- [ ] Edge cases handled gracefully
