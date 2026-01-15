# Views Directory

This directory contains all main screens/views of the app.

---

## Files Overview

| File | Purpose | Priority |
|------|---------|----------|
| HomeView.swift | Main screen, workout config, START | P0 |
| EMOMTimerView.swift | Active EMOM workout | P0 |
| RoundsTimerView.swift | Active Rounds workout | P1 |
| SummaryView.swift | Post-workout stats + notes | P1 |
| HistoryView.swift | List of past workouts | P2 |
| HistoryDetailView.swift | Single workout details | P2 |

---

## HomeView.swift

**Purpose:** Landing screen where user configures and starts workout

**Layout (ASCII):**
```
┌─────────────────────────────────┐
│  ARMOR                          │
├─────────────────────────────────┤
│  LAST WORKOUT                   │
│  2×20kg · 18/20 rounds          │
│  Jan 14                         │
├─────────────────────────────────┤
│  [EMOM]  [ROUNDS]               │  ← Segmented control
│                                 │
│  WEIGHT                         │
│  [Single ▼] [20 kg ▼]           │  ← WeightPicker component
│                                 │
│  DURATION                       │  ← DurationPicker component
│  [20 minutes ▼]                 │
│                                 │
│  ┌─────────────────────────────┐│
│  │         START               ││
│  └─────────────────────────────┘│
│                                 │
│  [History]                      │
└─────────────────────────────────┘
```

**State:**
```swift
@Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
@State private var mode: WorkoutMode = .emom
@State private var kettlebellType: KBType = .double
@State private var weight: Int = 20
@State private var targetMinutes: Int = 20       // EMOM
@State private var targetRounds: Int = 15        // Rounds mode
@State private var restDuration: Int = 60        // Rounds mode
@State private var showingWorkout: Bool = false
```

**Behavior:**
- On appear: Pre-fill from `sessions.first` (last workout)
- Mode toggle shows/hides rest duration picker
- START navigates to EMOMTimerView or RoundsTimerView
- History button navigates to HistoryView

**Dependencies:**
- WeightPicker (Component)
- DurationPicker (Component)
- WorkoutSession (Model)
- AppColors, AppTypography (Design)

---

## EMOMTimerView.swift

**Purpose:** Active workout screen for Every-Minute-On-the-Minute mode

**Layout (ASCII):**
```
┌─────────────────────────────────┐
│  2×20kg                    ✕    │
├─────────────────────────────────┤
│                                 │
│           0:47                  │  ← Countdown to next minute
│                                 │
│       ROUND 7/20                │
│                                 │
│    Total: 06:23                 │
│                                 │
│  ┌─────────────────────────────┐│
│  │       SET DONE              ││
│  └─────────────────────────────┘│
│                                 │
│  Last set: 42s                  │
└─────────────────────────────────┘
```

**State:**
```swift
// Passed in
let kettlebellType: KBType
let weight: Int
let targetMinutes: Int

// Internal
@State private var currentRound: Int = 0
@State private var secondsIntoMinute: Double = 0     // 0-60, resets each minute
@State private var totalElapsed: TimeInterval = 0
@State private var setTimes: [TimeInterval] = []
@State private var setStartTime: Date? = nil
@State private var phase: TimerPhase = .getReady     // .getReady, .active, .complete
@State private var isSetInProgress: Bool = false

@Environment(\.modelContext) private var modelContext
@Environment(\.dismiss) private var dismiss

let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
```

**Timer Logic (Critical):**

```
Phase 1: GET READY (5 seconds)
  - Display "GET READY" with 5-4-3-2-1 countdown
  - At 0: transition to ACTIVE, play GO beep

Phase 2: ACTIVE
  - Each minute:
    1. At :00 → play GO beep, increment round, start set timer
    2. Display countdown: 60 - secondsIntoMinute
    3. User taps "SET DONE":
       - Log time (totalElapsed - setStartTime)
       - setStartTime = nil
       - isSetInProgress = false
    4. At :55 → play warning beeps (5-4-3-2-1)
    5. At :60 → reset secondsIntoMinute to 0, loop

  - If user hasn't tapped SET DONE by :60:
    - Keep timer running past 60 (shows "OVERTIME" or negative)
    - When they finally tap, log the overtime
    - Wait for NEXT minute marker before GO beep

  - When currentRound == targetMinutes AND set is done:
    - Transition to COMPLETE

Phase 3: COMPLETE
  - Stop timer
  - Create WorkoutSession with all data
  - Navigate to SummaryView
```

**Audio Cues:**
- 5-4-3-2-1 countdown beeps before each minute (at :55-59)
- Big beep at :00 (start of minute)
- Use AudioManager utility

**Exit Handling:**
- X button: Confirm dialog → discard and return home
- Don't save incomplete sessions

**Dependencies:**
- TimerDisplay (Component)
- AudioManager (Utility)
- WorkoutSession (Model)
- AppColors, AppTypography (Design)

---

## RoundsTimerView.swift

**Purpose:** Active workout screen for Rounds-with-Rest mode

**Layout:** Similar to EMOM but countdown shows rest time remaining

**Key Differences from EMOM:**
- After "SET DONE", rest countdown starts immediately
- Countdown shows rest time (e.g., 60s → 0s)
- At rest end → beep → next round
- No "overtime" concept (set time doesn't affect rest)

**State:**
```swift
let kettlebellType: KBType
let weight: Int
let targetRounds: Int
let restDuration: Int              // Seconds

@State private var currentRound: Int = 0
@State private var phase: RoundsPhase = .getReady   // .getReady, .working, .resting, .complete
@State private var restCountdown: Int = 0
@State private var totalElapsed: TimeInterval = 0
@State private var setTimes: [TimeInterval] = []
@State private var setStartTime: Date? = nil
```

**Timer Logic:**
```
Phase 1: GET READY (5 seconds)
  - Same as EMOM

Phase 2: WORKING
  - User is doing the set
  - No countdown shown (or show elapsed)
  - "SET DONE" → log time → transition to RESTING

Phase 3: RESTING
  - Show rest countdown (60...0)
  - At :05 → warning beeps
  - At :00 → beep → transition to WORKING, increment round

Repeat WORKING/RESTING until currentRound == targetRounds AND set done
Then → COMPLETE
```

**Dependencies:** Same as EMOMTimerView

---

## SummaryView.swift

**Purpose:** Post-workout stats display and notes entry

**Layout (ASCII):**
```
┌─────────────────────────────────┐
│  WORKOUT COMPLETE               │
├─────────────────────────────────┤
│  18/20 ROUNDS                   │
│                                 │
│  Total Time     19:47           │
│  Avg Set Time   43s             │
│  Weight         2×20kg          │
├─────────────────────────────────┤
│  SET BREAKDOWN          [Show ▼]│
│  R1: 41s  R2: 43s  R3: 45s      │
│  R7: 1:02 ⚠️                     │  ← Overtime marked
├─────────────────────────────────┤
│  NOTES                          │
│  ┌─────────────────────────────┐│
│  │                             ││
│  └─────────────────────────────┘│
│                                 │
│  [SAVE]                         │
└─────────────────────────────────┘
```

**Input:**
```swift
let session: WorkoutSession        // Already created by timer view
```

**State:**
```swift
@State private var notes: String = ""
@State private var showBreakdown: Bool = false
@Environment(\.dismiss) private var dismiss
```

**Behavior:**
- Display all stats from session
- Allow expanding set breakdown
- Notes text field (multiline)
- SAVE: Update session.notes, session.isCompleted = true, dismiss to home

**Dependencies:**
- WorkoutSession (Model)
- AppColors, AppTypography (Design)

---

## HistoryView.swift

**Purpose:** List of all past workouts

**Layout (ASCII):**
```
┌─────────────────────────────────┐
│  ← HISTORY                      │
├─────────────────────────────────┤
│  Jan 15                         │
│  2×20kg · 20/20 · EMOM          │
├─────────────────────────────────┤
│  Jan 14                         │
│  2×20kg · 18/20 · EMOM          │
│  "Grip failed on 18"            │
├─────────────────────────────────┤
│  Jan 12                         │
│  2×18kg · 15/15 · Rounds        │
└─────────────────────────────────┘
```

**State:**
```swift
@Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
```

**Behavior:**
- Simple List with ForEach
- Each row shows: date, weight, rounds, mode, note preview (if exists)
- Tap row → navigate to HistoryDetailView
- Swipe to delete (optional for MVP)

**Dependencies:**
- WorkoutSession (Model)
- HistoryDetailView (Navigation)
- AppColors, AppTypography (Design)

---

## HistoryDetailView.swift

**Purpose:** Full details of a single workout session

**Layout:** Similar to SummaryView but read-only, with ability to edit notes

**Input:**
```swift
let session: WorkoutSession
```

**Features:**
- All stats displayed
- Set breakdown (always expanded or toggle)
- Notes displayed (with edit capability)
- Back navigation

**Dependencies:**
- WorkoutSession (Model)
- AppColors, AppTypography (Design)

---

## Navigation Flow

```
HomeView
    │
    ├──[START (EMOM)]──→ EMOMTimerView ──→ SummaryView ──→ HomeView
    │
    ├──[START (Rounds)]─→ RoundsTimerView ──→ SummaryView ──→ HomeView
    │
    └──[History]──→ HistoryView ──→ HistoryDetailView
                         │
                         └──[Back]──→ HistoryView ──→ HomeView
```

Use NavigationStack for this flow:
```swift
@main
struct KB_TrackerApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
        }
        .modelContainer(for: WorkoutSession.self)
    }
}
```

---

## Implementation Order

1. **HomeView** - Get basic navigation and state working
2. **EMOMTimerView** - Core timer logic (most complex)
3. **SummaryView** - Display results
4. **HistoryView** - List past sessions
5. **RoundsTimerView** - Similar to EMOM, adapt logic
6. **HistoryDetailView** - Detail expansion
