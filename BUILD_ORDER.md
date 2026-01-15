# Build Order - Armor Building Complex Tracker

Follow this sequence to implement the MVP. Each phase builds on the previous one.

---

## Phase 1: Foundation (Design System)

### Design/Colors.swift
- Implement hex color initializer
- Define AppColors struct with all color constants
- Ref: `Design/PLAN.md`
- **Effort:** 15 min
- **Blockers:** None

### Design/Typography.swift
- Define font sizes and weights
- Create AppTypography struct with all text styles
- Ref: `Design/PLAN.md`
- **Effort:** 10 min
- **Blockers:** None

### Models/WorkoutSession.swift
- Define enums: WorkoutMode, KBType
- Implement @Model class with all properties
- Add computed properties (weightDisplay, averageSetTime, etc.)
- Ref: `Models/PLAN.md`
- **Effort:** 20 min
- **Blockers:** None

### KB_TrackerApp.swift (Modify)
- Update ModelContainer to use WorkoutSession instead of Item
- Keep everything else the same
- Ref: `Models/PLAN.md`
- **Effort:** 5 min
- **Blockers:** None

### Delete Files
- Delete `Item.swift`
- Delete `ContentView.swift` (will replace with HomeView)

---

## Phase 2: Core Timer Logic

### Components/TimerDisplay.swift
- Implement reusable timer display component
- Handle monospaced digits
- Support overtime coloring
- Ref: `Components/PLAN.md`
- **Effort:** 15 min
- **Blockers:** Design/ (Phase 1)

### Components/WeightPicker.swift
- Implement weight selector (Single/Double + kg)
- Use Picker menus
- Ref: `Components/PLAN.md`
- **Effort:** 15 min
- **Blockers:** Design/, Models/

### Components/DurationPicker.swift
- Implement duration picker
- Handle EMOM (minutes) vs Rounds (rounds + rest) modes
- Ref: `Components/PLAN.md`
- **Effort:** 20 min
- **Blockers:** Design/, Models/

### Utilities/AudioManager.swift
- Implement audio playback for beeps
- Use system sounds or custom audio
- Handle AVAudioSession configuration
- Ref: `Utilities/PLAN.md`
- **Effort:** 20 min
- **Blockers:** None

---

## Phase 3: Navigation & Home

### Views/HomeView.swift
- Display last workout (query from history)
- Mode toggle (EMOM vs Rounds)
- Weight picker
- Duration picker
- START button
- History link
- Ref: `Views/PLAN.md`
- **Effort:** 30 min
- **Blockers:** Design/, Models/, Components/
- **Test:** App launches to HomeView, shows last workout data

---

## Phase 4: EMOM Timer (Most Complex)

### Views/EMOMTimerView.swift
- Receive workout config from HomeView
- Implement timer logic:
  - 5-second GET READY countdown
  - Minute-based countdown (0:60 → 0:00)
  - SET DONE button logs time
  - Audio cues at key moments
  - Handle overtime (>60 seconds)
  - Auto-complete after targetMinutes reached
- Exit button (discard partial workout)
- Display: current countdown, rounds progress, elapsed time, last set time
- Ref: `Views/PLAN.md` (critical timer logic section)
- **Effort:** 60-90 min (most complex)
- **Blockers:** Design/, Models/, Components/, Utilities/
- **Test:**
  - Verify 5-second countdown works
  - Verify beep at :00
  - Verify SET DONE logs times correctly
  - Verify rest period to next minute works
  - Verify overtime handling

---

## Phase 5: Summary & Persistence

### Views/SummaryView.swift
- Receive completed WorkoutSession from EMOMTimerView
- Display stats: rounds, total time, avg set time, weight
- Expandable set breakdown (show all set times)
- Mark overtime sets with warning indicator
- Notes text input (multiline)
- SAVE button: update session, set isCompleted = true, insert into database
- Ref: `Views/PLAN.md`
- **Effort:** 25 min
- **Blockers:** Design/, Models/, Views/EMOMTimerView
- **Test:**
  - Complete EMOM workout, verify summary shows correct stats
  - Add notes, save, verify session persists

---

## Phase 6: History View

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
- **Blockers:** Design/, Models/, Views/SummaryView
- **Test:**
  - Complete a workout, verify it appears in history
  - Verify last workout pre-fills HomeView

### Views/HistoryDetailView.swift
- Receive single WorkoutSession
- Display all stats (same as SummaryView)
- Show full set breakdown
- Show notes
- Optional: Edit notes + save back to database
- Back button to return to HistoryView
- Ref: `Views/PLAN.md`
- **Effort:** 15 min
- **Blockers:** Design/, Models/, Views/HistoryView

---

## Phase 7: Rounds Timer (Variant of EMOM)

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
- **Blockers:** Design/, Models/, Components/, Utilities/, Views/EMOMTimerView
- **Test:**
  - Set 3 rounds, 30 second rest
  - Verify REST countdown works
  - Verify beeps at key moments
  - Verify correct rounds completed before ending

---

## Phase 8: Polish & Edge Cases

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

| Phase | File(s) | Priority | Effort |
|-------|---------|----------|--------|
| 1 | Design/ + Models/ | P0 | 50 min |
| 2 | Components/ + Utilities/ | P0 | 70 min |
| 3 | HomeView | P0 | 30 min |
| 4 | EMOMTimerView | P0 | 90 min |
| 5 | SummaryView | P1 | 25 min |
| 6 | HistoryView + HistoryDetailView | P2 | 35 min |
| 7 | RoundsTimerView | P2 | 45 min |
| 8 | Polish & Testing | P3 | 60 min |

**Total Estimated Time: ~405 minutes (~6.75 hours)**

---

## Quick Start

1. Open Xcode
2. Start with Phase 1 (Design System)
3. Before each phase, read the PLAN.md file in that directory
4. Copy code examples from PLAN.md into the empty .swift files
5. Test each phase before moving to the next
6. Use Xcode's simulator (cmd+R) to run and test

---

## Testing Checklist

### After Phase 1
- [ ] Colors are defined and accessible
- [ ] Typography is defined and accessible
- [ ] WorkoutSession compiles and has all properties
- [ ] App launches without errors

### After Phase 3
- [ ] HomeView displays with no data (empty state)
- [ ] Mode toggle switches between EMOM/Rounds
- [ ] Weight picker has correct options
- [ ] Duration picker shows correct fields for mode
- [ ] START button is tappable (doesn't crash)

### After Phase 4
- [ ] EMOM timer starts with 5-second countdown
- [ ] Beep plays at :00
- [ ] SET DONE button logs completion time
- [ ] Timer continues to next minute
- [ ] Workout ends after targetMinutes
- [ ] Can exit mid-workout

### After Phase 5
- [ ] Summary shows all stats correctly
- [ ] Can add notes
- [ ] SAVE persists workout to database
- [ ] No crashes

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
