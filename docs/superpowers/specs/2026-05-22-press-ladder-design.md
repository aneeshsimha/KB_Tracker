# Press Ladder Workout — Design Spec

_Date: 2026-05-22_

## Context

KB Tracker currently implements one workout: the **ABC complex** (2 cleans · 1 press · 3 front
squats) run in either **EMOM** or **Rounds** timing mode. Dan John's Armor Building program pairs
the ABC complex with a second, complementary workout — the **press ladder** (2-3-5-10 rep ladder),
a volume-focused overhead pressing day. On any given training day you do **one or the other**, not
both.

This spec adds the press ladder as a **peer workout** to the ABC complex. The goal is to let the
user pick ABC or Press on Home and run/track a press session, reusing the existing design system,
persistence, and history.

Key product facts that shaped the design:
- A ladder is **2 → 3 → 5 → 10 reps = 20 reps**. Rungs are fixed (not configurable in v1).
- "Volume is the point, not load" — the tracked metric is **reps/ladders**, not time or weight.
- The session is **rest-as-needed**: no enforced clock, just a running stopwatch.

## Decisions (resolved during brainstorming)

1. **Run model:** rep-ladder, rest-as-needed. The user taps to log each rung as they finish it;
   the app tallies total reps and ladders. A stopwatch runs but imposes nothing.
2. **Placement:** a top-level `WORKOUT` segmented toggle on Home (ABC COMPLEX | PRESS LADDER) that
   swaps the setup below it. ABC's setup is unchanged.
3. **Data model:** add a `WorkoutType {abc, press}` discriminator to the existing `WorkoutSession`;
   ABC and Press share **one unified History list**. Press uses its own fields; ABC fields are
   untouched. A **separate** lightweight `PressLadderViewModel` drives the press flow (the existing
   minute-clock `TimerViewModel` is not reused).

## Workout structure (fixed)

- Rungs: `[2, 3, 5, 10]` → one full ladder = 20 reps.
- Target ladders: user-selectable, **default 5** (= 100 reps), range **1–10**.
- Load: reuse the existing weight picker (12–24 kg, step 2) + Single/Double. **Default Single 16.**

## Home setup changes (`HomeView.swift`)

- Add `@State workoutType: WorkoutType = .abc`.
- Add a `WORKOUT` `SegmentedToggle` (ABC COMPLEX | PRESS LADDER) at the top, above the existing
  MODE control.
- When `.abc`: render today's setup exactly as-is (MODE EMOM/Rounds, LOAD dial, DURATION/ROUNDS
  dial). START routes to the existing `EMOMTimerView` / `RoundsTimerView`.
- When `.press`: render
  - a `LADDERS` `Dial` (target ladders, default 5, range 1–10, step 1)
  - the existing `LOAD` `Dial` (weight + Single/Double)
  - START button labeled "Start · N ladders" → routes to `PressLadderView(config:)`.
- Extend the existing `fileprivate enum HomeRoute` with a `.press` case.
- Prefill: keep the existing ABC prefill from last session. Press setup uses its own defaults
  (no prefill required in v1).

## Active flow (`PressLadderView.swift` + `PressLadderViewModel.swift`)

New, self-contained. **Does not** touch `TimerViewModel`.

`PressLadderViewModel` (ObservableObject, @MainActor):
- Inputs: `WorkoutConfig` (press).
- State: `currentLadder: Int` (1-indexed), `currentRungIndex: Int` (0..3 into `[2,3,5,10]`),
  `ladderReps: [Int]` (accumulated full ladders), `currentLadderReps: Int` (partial accumulator),
  `totalElapsed: TimeInterval` (stopwatch, 0.1s tick or Date-anchored), `phase {active, complete}`,
  `completedSession`/`partialSession`.
- `logRung()`: add the current rung's reps to `currentLadderReps`; advance rung. After rung 10:
  push 20 to `ladderReps`, reset rung to 0, `currentLadder += 1`; if `currentLadder > targetLadders`
  → complete. Optional ladder-complete audio cue; completion sound on finish.
- `undoLastRung()`: reverse the last `logRung()` (guards mis-taps).
- `endEarly()` / `savePartial()`: push the partial ladder's reps and build a session with
  `isCompleted = false`.
- `start()` / `stop()` for the stopwatch.

`PressLadderView` layout (reusing atoms):
- Chrome: `LADDER n/target` with an END pill (left) — reuse the timer chrome pattern or a local
  header; END opens `ConfirmSheet` ("End this session? / Your progress won't be saved.").
- Rung indicator: `2 · 3 · [5] · 10` with the current rung highlighted (small custom row).
- Focal: large mono numeral = current rung's reps.
- Running **total reps** tally.
- 76pt `LOG <n> REPS` `PrimaryButton`; a subtle **undo last rung** affordance.
- No GET READY countdown — START goes straight into Ladder 1, rung 2, stopwatch running.

## Data model (`WorkoutSession.swift`, `Enums.swift`, `WorkoutConfig.swift`)

`Enums.swift`: add
```swift
enum WorkoutType: String, Codable { case abc, press }
```

`WorkoutSession` (lightweight SwiftData migration — every new property has a default, so existing
sessions remain valid and default to `.abc`):
- `private var workoutTypeRaw: String = WorkoutType.abc.rawValue` + computed `workoutType` getter/setter.
- `var targetLadders: Int = 0`
- `var ladderReps: [Int] = []`  (reps per ladder; full = 20)
- Reuse `weight`, `kettlebellType`, `totalDuration` (stopwatch seconds), `notes`, `isCompleted`, `date`.
- ABC-only fields (`mode`, `setTimes`, `restDuration`, `completedRounds`, `targetRounds`) stay at
  defaults and are unused for press.
- Computed helpers:
  - `totalReps: Int { ladderReps.reduce(0, +) }`
  - `completedLadders: Int { ladderReps.filter { $0 == 20 }.count }`

`WorkoutConfig`: add
```swift
static func press(kettlebellType: KBType, weight: Int, targetLadders: Int) -> WorkoutConfig
```
Carry `workoutType` on the config; for press, `targetLadders` is used and timing fields are unused.

## Complete screen (`WorkoutCompleteView.swift` — branch by `session.workoutType`)

Press branch:
- Hero: "<totalReps> presses\nat <weightDisplay>." (same heavy 36pt treatment).
- Body: "<completedLadders> ladders of 2·3·5·10."
- Stat tiles: TOTAL REPS / LADDERS (completed/target) / TIME (totalDuration) / AVG·LADDER (time).
- A per-ladder bar chart (reps, full = 20) — reuse `SparkBars`/`SetChart` style adapted to rep
  values, or a small local bar view if the rep semantics don't fit `SetChart` cleanly.
- Notes + Save reuse the **existing** save path verbatim (set notes, `isCompleted`, insert, dismiss,
  `onSaveComplete`).

ABC branch is the current implementation, unchanged.

## History (`HistoryView.swift` + `HistoryDetailView.swift` — unified list, branch by type)

- The `@Query` list includes both types; the 8-week arc and weekly grouping count both.
- Press row: "Press · <weightDisplay>" / "<totalReps> reps · <completedLadders> ladders" with a
  per-ladder micro spark.
- Press detail: hero `<totalReps>`, stat tiles, a per-ladder grid (L01: 20, L02: 20, …), editable
  notes, delete via `ConfirmSheet` — mirroring ABC detail.

## Files touched

New:
- `KB_Tracker/Views/PressLadderView.swift`
- `KB_Tracker/ViewModels/PressLadderViewModel.swift`

Edited:
- `KB_Tracker/Models/Enums.swift` (add `WorkoutType`)
- `KB_Tracker/Models/WorkoutSession.swift` (discriminator + press fields + computed helpers)
- `KB_Tracker/Models/WorkoutConfig.swift` (add `.press` builder + `workoutType`)
- `KB_Tracker/Views/HomeView.swift` (WORKOUT toggle, press setup, `.press` route)
- `KB_Tracker/Views/WorkoutCompleteView.swift` (type branch)
- `KB_Tracker/Views/HistoryView.swift`, `HistoryDetailView.swift` (type branch)

Reuses all existing design atoms (`Eyebrow`, `KBCard`, `Dial`, `SegmentedToggle`, `PrimaryButton`,
`StatTile`, `SparkBars`, `KettlebellGlyph`, `ConfirmSheet`, `IconButton`).

## Out of scope (v1, YAGNI)

- Configurable rungs / custom ladder shapes.
- Program scheduling / alternating ABC↔Press day logic.
- Per-rung timing or enforced rest clocks.
- Propagating onboarding's chosen kit into Home defaults (pre-existing minor gap, tracked separately).

## Verification

- `xcodebuild -scheme KB_Tracker -destination 'generic/platform=iOS Simulator' build` → BUILD SUCCEEDED.
- Run on the iOS 26.2 simulator and walk: Home → WORKOUT = Press Ladder → set ladders/load →
  START → log rungs 2,3,5,10 (ladder advances), test **undo**, complete the target → Complete
  (verify totalReps, ladders, time) → Save → History (press row appears in the unified list with
  per-ladder spark) → Detail (per-ladder grid) → delete. Confirm an ABC session still runs and
  displays unchanged, and that existing saved sessions still load (migration: default `.abc`).
