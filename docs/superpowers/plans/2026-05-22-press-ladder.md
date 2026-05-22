# Press Ladder Workout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Dan John's 2-3-5-10 press ladder as a peer workout to the ABC complex — selectable on Home, run as a rep-ladder with a stopwatch, stored in the unified history.

**Architecture:** Extend `WorkoutSession` with a `WorkoutType {abc, press}` discriminator + press-only fields (additive SwiftData migration, all defaulted). A new pure `PressLadderViewModel` owns the rung/ladder state machine (no audio side-effects — the view triggers cues via `onChange`). A new `PressLadderView` renders the active flow and presents the existing `WorkoutCompleteView`. `HomeView`, `WorkoutCompleteView`, and `HistoryView`/`HistoryDetailView` branch on `workoutType`. All existing design atoms are reused.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing (`import Testing`), iOS 26.2, Xcode 26.

**Test execution:** unit tests run on the iOS 26.2 simulator already created this session:
`xcodebuild test -scheme KB_Tracker -destination 'platform=iOS Simulator,id=BC2D9E5A-17C6-4478-9F06-996326F22699'`
(If that UDID is gone, recreate: `xcrun simctl create KB-26 "iPhone 16 Pro" com.apple.CoreSimulator.SimRuntime.iOS-26-2` and use its id, or use any `OS:26.2` device from `xcodebuild -scheme KB_Tracker -showdestinations`.)
Build-only check: `xcodebuild -scheme KB_Tracker -destination 'generic/platform=iOS Simulator' build`.

**Sequencing note:** Tasks are dependency-ordered and several edit shared files — run them **sequentially**, not in parallel.

---

## File Structure

New:
- `KB_Tracker/ViewModels/PressLadderViewModel.swift` — pure rung/ladder state machine + stopwatch.
- `KB_Tracker/Views/PressLadderView.swift` — active press flow; presents `WorkoutCompleteView`.
- `KB_TrackerTests/PressLadderModelTests.swift` — model + config unit tests.
- `KB_TrackerTests/PressLadderViewModelTests.swift` — view-model unit tests.

Modified:
- `KB_Tracker/Models/Enums.swift` — add `WorkoutType`.
- `KB_Tracker/Models/WorkoutSession.swift` — discriminator + press fields + computed helpers.
- `KB_Tracker/Models/WorkoutConfig.swift` — `workoutType`, `targetLadders`, `.press` builder.
- `KB_Tracker/Views/HomeView.swift` — WORKOUT toggle, press setup, `.press` route.
- `KB_Tracker/Views/WorkoutCompleteView.swift` — branch hero/stats/chart by type.
- `KB_Tracker/Views/HistoryView.swift` + `HistoryDetailView.swift` — branch row/detail by type.

---

## Task 1: WorkoutType + WorkoutSession press fields (TDD)

**Files:**
- Modify: `KB_Tracker/Models/Enums.swift`
- Modify: `KB_Tracker/Models/WorkoutSession.swift`
- Test: `KB_TrackerTests/PressLadderModelTests.swift` (create)

- [ ] **Step 1: Write the failing tests**

Create `KB_TrackerTests/PressLadderModelTests.swift`:

```swift
import Testing
import Foundation
@testable import KB_Tracker

struct PressLadderModelTests {
    @Test func workoutTypeDefaultsToABC() {
        #expect(WorkoutSession().workoutType == .abc)
    }

    @Test func workoutTypeRoundTrips() {
        let s = WorkoutSession()
        s.workoutType = .press
        #expect(s.workoutType == .press)
    }

    @Test func totalRepsSumsLadderReps() {
        let s = WorkoutSession()
        s.ladderReps = [20, 20, 15]
        #expect(s.totalReps == 55)
    }

    @Test func completedLaddersCountsFullLaddersOnly() {
        let s = WorkoutSession()
        s.ladderReps = [20, 20, 15]
        #expect(s.completedLadders == 2)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme KB_Tracker -destination 'platform=iOS Simulator,id=BC2D9E5A-17C6-4478-9F06-996326F22699' -only-testing:KB_TrackerTests/PressLadderModelTests 2>&1 | tail -20`
Expected: FAIL — compile errors, `workoutType` / `ladderReps` / `totalReps` / `completedLadders` not members of `WorkoutSession`.

- [ ] **Step 3: Add `WorkoutType` to Enums.swift**

Append to `KB_Tracker/Models/Enums.swift`:

```swift
/// Which workout this session is: the ABC complex or the press ladder.
enum WorkoutType: String, Codable {
    case abc      // 2 cleans · 1 press · 3 front squats (EMOM/Rounds)
    case press    // 2-3-5-10 press ladder
}
```

- [ ] **Step 4: Add press fields + computed helpers to WorkoutSession**

In `KB_Tracker/Models/WorkoutSession.swift`, add stored properties after `var isCompleted` (inside the `@Model` class):

```swift
    private var workoutTypeRaw: String = WorkoutType.abc.rawValue
    var targetLadders: Int = 0          // press: target number of 2-3-5-10 ladders
    var ladderReps: [Int] = []          // press: reps completed per ladder (full = 20)
```

Add to the computed-properties block (next to `mode`/`kettlebellType`):

```swift
    var workoutType: WorkoutType {
        get { WorkoutType(rawValue: workoutTypeRaw) ?? .abc }
        set { workoutTypeRaw = newValue.rawValue }
    }
```

Add to the `extension WorkoutSession` computed block:

```swift
    // Press: total reps across all ladders (including a trailing partial).
    var totalReps: Int { ladderReps.reduce(0, +) }

    // Press: number of fully-completed ladders (20 reps each).
    var completedLadders: Int { ladderReps.filter { $0 == 20 }.count }
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -scheme KB_Tracker -destination 'platform=iOS Simulator,id=BC2D9E5A-17C6-4478-9F06-996326F22699' -only-testing:KB_TrackerTests/PressLadderModelTests 2>&1 | tail -20`
Expected: PASS (4 tests). If the test file isn't picked up, confirm `KB_TrackerTests` uses a synchronized folder group (it does for the app target); the new file auto-joins.

- [ ] **Step 6: Commit**

```bash
git add KB_Tracker/Models/Enums.swift KB_Tracker/Models/WorkoutSession.swift KB_TrackerTests/PressLadderModelTests.swift
git commit -m "Add WorkoutType discriminator and press fields to WorkoutSession"
```

---

## Task 2: WorkoutConfig press builder (TDD)

**Files:**
- Modify: `KB_Tracker/Models/WorkoutConfig.swift`
- Test: `KB_TrackerTests/PressLadderModelTests.swift` (extend)

- [ ] **Step 1: Add failing tests**

Append these `@Test` methods inside `struct PressLadderModelTests`:

```swift
    @Test func pressConfigBuilds() {
        let c = WorkoutConfig.press(kettlebellType: .single, weight: 16, targetLadders: 5)
        #expect(c.workoutType == .press)
        #expect(c.targetLadders == 5)
        #expect(c.weight == 16)
        #expect(c.kettlebellType == .single)
    }

    @Test func emomConfigIsABC() {
        let c = WorkoutConfig.emom(kettlebellType: .double, weight: 20, minutes: 20)
        #expect(c.workoutType == .abc)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme KB_Tracker -destination 'platform=iOS Simulator,id=BC2D9E5A-17C6-4478-9F06-996326F22699' -only-testing:KB_TrackerTests/PressLadderModelTests 2>&1 | tail -20`
Expected: FAIL — `workoutType` / `targetLadders` not members of `WorkoutConfig`; `press(...)` missing.

- [ ] **Step 3: Update WorkoutConfig**

Replace the body of `struct WorkoutConfig` in `KB_Tracker/Models/WorkoutConfig.swift` with (preserving the existing `weightDisplay`):

```swift
struct WorkoutConfig {
    let workoutType: WorkoutType
    let mode: WorkoutMode            // meaningful for .abc only
    let kettlebellType: KBType
    let weight: Int
    let targetRounds: Int            // ABC EMOM: minutes; ABC Rounds: round count
    let restDuration: Int?           // ABC Rounds only
    let targetLadders: Int           // press only

    static func emom(kettlebellType: KBType, weight: Int, minutes: Int) -> WorkoutConfig {
        WorkoutConfig(workoutType: .abc, mode: .emom, kettlebellType: kettlebellType,
                      weight: weight, targetRounds: minutes, restDuration: nil, targetLadders: 0)
    }

    static func rounds(kettlebellType: KBType, weight: Int, rounds: Int, restSeconds: Int) -> WorkoutConfig {
        WorkoutConfig(workoutType: .abc, mode: .rounds, kettlebellType: kettlebellType,
                      weight: weight, targetRounds: rounds, restDuration: restSeconds, targetLadders: 0)
    }

    static func press(kettlebellType: KBType, weight: Int, targetLadders: Int) -> WorkoutConfig {
        WorkoutConfig(workoutType: .press, mode: .emom, kettlebellType: kettlebellType,
                      weight: weight, targetRounds: 0, restDuration: nil, targetLadders: targetLadders)
    }

    var weightDisplay: String {
        switch kettlebellType {
        case .single: return "\(weight)kg"
        case .double: return "2×\(weight)kg"
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme KB_Tracker -destination 'platform=iOS Simulator,id=BC2D9E5A-17C6-4478-9F06-996326F22699' -only-testing:KB_TrackerTests/PressLadderModelTests 2>&1 | tail -20`
Expected: PASS (6 tests). The existing `HomeView` calls to `.emom`/`.rounds` still compile (signatures unchanged).

- [ ] **Step 5: Commit**

```bash
git add KB_Tracker/Models/WorkoutConfig.swift KB_TrackerTests/PressLadderModelTests.swift
git commit -m "Add press builder and workoutType to WorkoutConfig"
```

---

## Task 3: PressLadderViewModel (TDD)

**Files:**
- Create: `KB_Tracker/ViewModels/PressLadderViewModel.swift`
- Test: `KB_TrackerTests/PressLadderViewModelTests.swift` (create)

- [ ] **Step 1: Write failing tests**

Create `KB_TrackerTests/PressLadderViewModelTests.swift`:

```swift
import Testing
import Foundation
@testable import KB_Tracker

@MainActor
struct PressLadderViewModelTests {
    private func makeVM(ladders: Int = 2) -> PressLadderViewModel {
        PressLadderViewModel(config: .press(kettlebellType: .single, weight: 16, targetLadders: ladders))
    }

    @Test func startsAtLadderOneRungTwo() {
        let vm = makeVM()
        #expect(vm.currentLadder == 1)
        #expect(vm.currentRungReps == 2)
        #expect(vm.totalReps == 0)
        #expect(vm.isComplete == false)
    }

    @Test func logRungAdvancesThroughRungs() {
        let vm = makeVM()
        vm.logRung()                       // logged 2 → rung 3
        #expect(vm.currentRungReps == 3)
        #expect(vm.totalReps == 2)
        vm.logRung(); vm.logRung()         // 3, then 5 → rung 10
        #expect(vm.currentRungReps == 10)
        #expect(vm.totalReps == 10)
    }

    @Test func completingLadderAdvancesToNext() {
        let vm = makeVM(ladders: 2)
        for _ in 0..<4 { vm.logRung() }    // full ladder (2+3+5+10)
        #expect(vm.currentLadder == 2)
        #expect(vm.currentRungReps == 2)
        #expect(vm.totalReps == 20)
        #expect(vm.isComplete == false)
    }

    @Test func finishesAtTargetLadders() {
        let vm = makeVM(ladders: 1)
        for _ in 0..<4 { vm.logRung() }
        #expect(vm.isComplete)
        #expect(vm.completedSession?.workoutType == .press)
        #expect(vm.completedSession?.totalReps == 20)
        #expect(vm.completedSession?.completedLadders == 1)
        #expect(vm.completedSession?.isCompleted == true)
    }

    @Test func undoStepsBackWithinLadder() {
        let vm = makeVM()
        vm.logRung()                       // total 2, rung 3
        vm.undoLastRung()
        #expect(vm.currentRungReps == 2)
        #expect(vm.totalReps == 0)
    }

    @Test func undoStepsBackAcrossLadderBoundary() {
        let vm = makeVM(ladders: 3)
        for _ in 0..<4 { vm.logRung() }    // completed ladder 1, now ladder 2 rung 2
        vm.undoLastRung()                  // back into ladder 1's rung 10
        #expect(vm.currentLadder == 1)
        #expect(vm.currentRungReps == 10)
        #expect(vm.totalReps == 10)        // 2+3+5 logged in the reopened ladder
    }

    @Test func endEarlySavesPartial() {
        let vm = makeVM(ladders: 5)
        vm.logRung(); vm.logRung()         // 2 + 3 = 5 reps into ladder 1
        vm.endEarly()
        #expect(vm.partialSession?.isCompleted == false)
        #expect(vm.partialSession?.totalReps == 5)
        #expect(vm.partialSession?.completedLadders == 0)
        #expect(vm.session?.totalReps == 5)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme KB_Tracker -destination 'platform=iOS Simulator,id=BC2D9E5A-17C6-4478-9F06-996326F22699' -only-testing:KB_TrackerTests/PressLadderViewModelTests 2>&1 | tail -20`
Expected: FAIL — `PressLadderViewModel` not found.

- [ ] **Step 3: Implement the view model**

Create `KB_Tracker/ViewModels/PressLadderViewModel.swift`:

```swift
// PressLadderViewModel.swift
// KB_Tracker
//
// State machine for the 2-3-5-10 press ladder. Pure logic + a stopwatch;
// no audio side-effects (the view plays cues via onChange).

import Foundation
import Combine

@MainActor
final class PressLadderViewModel: ObservableObject {
    /// Fixed rung sizes for one ladder.
    static let rungs = [2, 3, 5, 10]

    let config: WorkoutConfig

    @Published private(set) var currentLadder = 1        // 1-indexed
    @Published private(set) var currentRungIndex = 0     // 0..<rungs.count
    @Published private(set) var ladderReps: [Int] = []   // completed ladders (full = 20)
    @Published private(set) var currentLadderReps = 0    // reps in the in-progress ladder
    @Published private(set) var totalElapsed: TimeInterval = 0
    @Published private(set) var isComplete = false
    @Published private(set) var completedSession: WorkoutSession?
    @Published private(set) var partialSession: WorkoutSession?

    private var startDate: Date?
    private var timer: AnyCancellable?

    var targetLadders: Int { config.targetLadders }
    var currentRungReps: Int { Self.rungs[currentRungIndex] }
    var totalReps: Int { ladderReps.reduce(0, +) + currentLadderReps }
    var session: WorkoutSession? { completedSession ?? partialSession }

    init(config: WorkoutConfig) { self.config = config }

    func start() {
        startDate = Date()
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.startDate else { return }
                self.totalElapsed = Date().timeIntervalSince(start)
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    /// Log the current rung's reps and advance. Completes a ladder after rung 10.
    func logRung() {
        guard !isComplete else { return }
        currentLadderReps += Self.rungs[currentRungIndex]

        if currentRungIndex < Self.rungs.count - 1 {
            currentRungIndex += 1
        } else {
            // Ladder finished.
            ladderReps.append(currentLadderReps)
            currentLadderReps = 0
            currentRungIndex = 0
            if currentLadder >= targetLadders {
                finish(completed: true)
            } else {
                currentLadder += 1
            }
        }
    }

    /// Reverse the last `logRung()` — guards against mis-taps.
    func undoLastRung() {
        guard !isComplete else { return }
        if currentRungIndex > 0 {
            currentRungIndex -= 1
            currentLadderReps -= Self.rungs[currentRungIndex]
        } else if !ladderReps.isEmpty {
            // Step back into the previous ladder's final rung (the "10").
            ladderReps.removeLast()
            currentLadder -= 1
            currentRungIndex = Self.rungs.count - 1
            currentLadderReps = Self.rungs.dropLast().reduce(0, +) // 2+3+5 = 10
        }
    }

    func endEarly() { finish(completed: false) }

    private func finish(completed: Bool) {
        stop()
        var reps = ladderReps
        if currentLadderReps > 0 { reps.append(currentLadderReps) }

        let s = WorkoutSession()
        s.workoutType = .press
        s.kettlebellType = config.kettlebellType
        s.weight = config.weight
        s.targetLadders = config.targetLadders
        s.ladderReps = reps
        s.totalDuration = totalElapsed
        s.isCompleted = completed

        if completed {
            completedSession = s
            isComplete = true
        } else {
            partialSession = s
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme KB_Tracker -destination 'platform=iOS Simulator,id=BC2D9E5A-17C6-4478-9F06-996326F22699' -only-testing:KB_TrackerTests/PressLadderViewModelTests 2>&1 | tail -20`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add KB_Tracker/ViewModels/PressLadderViewModel.swift KB_TrackerTests/PressLadderViewModelTests.swift
git commit -m "Add PressLadderViewModel rung/ladder state machine"
```

---

## Task 4: PressLadderView (active flow)

**Files:**
- Create: `KB_Tracker/Views/PressLadderView.swift`

Verification is build + manual (SwiftUI view; no unit test).

- [ ] **Step 1: Create the view**

Create `KB_Tracker/Views/PressLadderView.swift`:

```swift
// PressLadderView.swift
// KB_Tracker
//
// Active press-ladder flow: rung indicator, focal rep count, LOG button,
// running stopwatch + total reps. Rest-as-needed (no enforced clock).

import SwiftUI
import SwiftData

struct PressLadderView: View {
    let config: WorkoutConfig

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: PressLadderViewModel

    @State private var showEndConfirm = false
    @State private var navigateToSummary = false

    init(config: WorkoutConfig) {
        self.config = config
        _vm = StateObject(wrappedValue: PressLadderViewModel(config: config))
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                rungIndicator.padding(.top, 18)

                Spacer()

                Text("\(vm.currentRungReps)")
                    .font(AppTypography.timerXL)
                    .foregroundColor(AppColors.ink)
                Eyebrow("reps this rung").padding(.top, 4)

                Text("\(vm.totalReps) total reps")
                    .font(AppTypography.mono(15, weight: .semibold))
                    .foregroundColor(AppColors.ink3)
                    .padding(.top, 24)

                Spacer()

                PrimaryButton(title: "Log \(vm.currentRungReps) Reps") { vm.logRung() }
                    .frame(height: 76)
                    .padding(.horizontal, 20)

                Button { vm.undoLastRung() } label: {
                    Text("Undo last rung")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.ink3)
                }
                .buttonStyle(TapScaleStyle())
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .onChange(of: vm.currentLadder) { _, _ in
            AudioService.shared.playGoBeep()
        }
        .onChange(of: vm.isComplete) { _, done in
            if done {
                AudioService.shared.playCompletionSound()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    navigateToSummary = true
                }
            }
        }
        .confirmSheet(
            isPresented: $showEndConfirm,
            title: "End this session?",
            message: "Your progress won't be saved.",
            confirmLabel: "End",
            cancelLabel: "Keep going"
        ) {
            dismiss()
        }
        .navigationDestination(isPresented: $navigateToSummary) {
            if let session = vm.session {
                WorkoutCompleteView(session: session) { dismiss() }
            }
        }
    }

    private var header: some View {
        HStack {
            Button { showEndConfirm = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: KBIcon.close.rawValue)
                    Text("END")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.ink2)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(AppColors.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppColors.hairline, lineWidth: 1))
            }
            .buttonStyle(TapScaleStyle())

            Spacer()
            Eyebrow("PRESS LADDER")
            Spacer()

            Text("\(vm.currentLadder)/\(vm.targetLadders)")
                .font(AppTypography.mono(12, weight: .regular))
                .foregroundColor(AppColors.ink3)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var rungIndicator: some View {
        HStack(spacing: 10) {
            ForEach(Array(PressLadderViewModel.rungs.enumerated()), id: \.offset) { i, reps in
                let isCurrent = i == vm.currentRungIndex
                Text("\(reps)")
                    .font(AppTypography.mono(16, weight: .bold))
                    .foregroundColor(isCurrent ? AppColors.background : AppColors.ink3)
                    .frame(width: 40, height: 40)
                    .background(isCurrent ? AppColors.ink : AppColors.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppColors.hairline, lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    NavigationStack {
        PressLadderView(config: .press(kettlebellType: .single, weight: 16, targetLadders: 5))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -scheme KB_Tracker -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD"`
Expected: `** BUILD SUCCEEDED **`. (`WorkoutCompleteView` still renders ABC content for a press session here — that's fixed in Task 6. It will compile and run.)

- [ ] **Step 3: Commit**

```bash
git add KB_Tracker/Views/PressLadderView.swift
git commit -m "Add PressLadderView active flow"
```

---

## Task 5: HomeView WORKOUT toggle + press setup + route

**Files:**
- Modify: `KB_Tracker/Views/HomeView.swift`

- [ ] **Step 1: Add the workout-type state**

In `HomeView`, add below `@State private var route: HomeRoute?`:

```swift
    @State private var workoutType: WorkoutType = .abc
    @State private var targetLadders: Int = 5        // press
```

- [ ] **Step 2: Add the WORKOUT toggle + branch the setup block**

Replace `setupBlock` with a version that shows the WORKOUT toggle first, then ABC or press setup:

```swift
    private var setupBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("WORKOUT")
                .padding(.bottom, 8)
            SegmentedToggle(
                options: [
                    SegmentedOption(label: "ABC", value: WorkoutType.abc),
                    SegmentedOption(label: "Press", value: WorkoutType.press),
                ],
                selection: $workoutType
            )
            .padding(.bottom, 22)

            if workoutType == .abc {
                abcSetup
            } else {
                pressSetup
            }
        }
        .padding(.top, 16)
    }

    private var abcSetup: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("MODE").padding(.bottom, 8)
            SegmentedToggle(
                options: [
                    SegmentedOption(label: "EMOM", value: WorkoutMode.emom),
                    SegmentedOption(label: "Rounds", value: WorkoutMode.rounds),
                ],
                selection: $mode
            )
            .padding(.bottom, 22)

            Dial(
                eyebrow: "LOAD",
                value: "\(weight)",
                unit: kettlebellType == .double ? "kg × 2" : "kg",
                onMinus: { stepWeight(-1) },
                onPlus: { stepWeight(+1) }
            ) {
                SegmentedToggle(
                    options: [
                        SegmentedOption(label: "Single", value: KBType.single),
                        SegmentedOption(label: "Double", value: KBType.double),
                    ],
                    selection: $kettlebellType,
                    inline: true
                )
                .padding(.top, 2)
            }

            Spacer().frame(height: 14)
            durationDial
        }
    }

    private var pressSetup: some View {
        VStack(alignment: .leading, spacing: 0) {
            Dial(
                eyebrow: "LADDERS",
                value: "\(targetLadders)",
                unit: "× 2·3·5·10",
                onMinus: { targetLadders = max(1, targetLadders - 1) },
                onPlus: { targetLadders = min(10, targetLadders + 1) }
            ) {
                HStack {
                    Text("Total reps")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.ink3)
                    Spacer()
                    Text("\(targetLadders * 20)")
                        .font(AppTypography.mono(12, weight: .regular))
                        .foregroundColor(AppColors.ink3)
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)
                .overlay(alignment: .top) {
                    Rectangle().fill(AppColors.hairline).frame(height: 1)
                }
                .padding(.top, 4)
            }

            Spacer().frame(height: 14)

            Dial(
                eyebrow: "LOAD",
                value: "\(weight)",
                unit: kettlebellType == .double ? "kg × 2" : "kg",
                onMinus: { stepWeight(-1) },
                onPlus: { stepWeight(+1) }
            ) {
                SegmentedToggle(
                    options: [
                        SegmentedOption(label: "Single", value: KBType.single),
                        SegmentedOption(label: "Double", value: KBType.double),
                    ],
                    selection: $kettlebellType,
                    inline: true
                )
                .padding(.top, 2)
            }
        }
    }
```

- [ ] **Step 3: Update the START title and route**

Replace `startTitle`:

```swift
    private var startTitle: String {
        switch workoutType {
        case .abc:   return mode == .emom ? "Start · \(targetMinutes) min" : "Start · \(targetRounds) rounds"
        case .press: return "Start · \(targetLadders) ladders"
        }
    }
```

Replace the footer button's action in `body` (currently `route = mode == .emom ? .emom : .rounds`):

```swift
                PrimaryButton(title: startTitle) {
                    switch workoutType {
                    case .abc:   route = mode == .emom ? .emom : .rounds
                    case .press: route = .press
                    }
                }
```

- [ ] **Step 4: Add the `.press` route**

In `HomeRoute` add `case press` (keep `var id: Self { self }`):

```swift
fileprivate enum HomeRoute: Hashable, Identifiable {
    case emom
    case rounds
    case press
    case history
    var id: Self { self }
}
```

In the `.navigationDestination(item: $route)` switch, add:

```swift
            case .press:
                PressLadderView(
                    config: .press(
                        kettlebellType: kettlebellType,
                        weight: weight,
                        targetLadders: targetLadders
                    )
                )
```

- [ ] **Step 5: Build**

Run: `xcodebuild -scheme KB_Tracker -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD"`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Commit**

```bash
git add KB_Tracker/Views/HomeView.swift
git commit -m "Add WORKOUT toggle and press setup to Home"
```

---

## Task 6: WorkoutCompleteView press branch

**Files:**
- Modify: `KB_Tracker/Views/WorkoutCompleteView.swift`

- [ ] **Step 1: Branch the scrollable content by type**

In `body`, replace the inner `VStack(alignment: .leading, spacing: 14) { hero; statsGrid; SetChart(...); notesCard }` with:

```swift
                    VStack(alignment: .leading, spacing: 14) {
                        if session.workoutType == .press {
                            pressHero
                            pressStatsGrid
                            pressLadderChart
                        } else {
                            hero
                            statsGrid
                            SetChart(setTimes: session.setTimes, mode: session.mode)
                        }
                        notesCard
                    }
```

- [ ] **Step 2: Add the press hero, stats, and chart**

Add these computed views inside `WorkoutCompleteView` (next to `hero`):

```swift
    private var pressHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("✓ COMPLETE", color: AppColors.green)
                .padding(.bottom, 8)
            (
                Text("\(session.totalReps) presses\n").foregroundColor(AppColors.ink)
                + Text("at \(weightPhrase).").foregroundColor(AppColors.ink3)
            )
            .font(.system(size: 36, weight: .heavy))
            .kerning(-0.8)
            .lineSpacing(2)
            .padding(.bottom, 10)

            Text("\(session.completedLadders) ladders of 2·3·5·10.")
                .font(AppTypography.bodyText)
                .foregroundColor(AppColors.ink2)
        }
        .padding(.vertical, 6)
    }

    private var pressStatsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        let avgLadder = session.completedLadders > 0
            ? session.totalDuration / Double(session.completedLadders) : 0
        return LazyVGrid(columns: columns, spacing: 10) {
            StatTile(label: "TOTAL REPS", value: "\(session.totalReps)")
            StatTile(label: "LADDERS", value: "\(session.completedLadders)/\(session.targetLadders)")
            StatTile(label: "TIME", value: mmss(session.totalDuration))
            StatTile(label: "AVG · LADDER", value: mmss(avgLadder))
        }
    }

    private var pressLadderChart: some View {
        KBCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Eyebrow("LADDER BREAKDOWN")
                    Spacer()
                    Eyebrow("\(session.ladderReps.count) LDR", color: AppColors.ink4)
                }
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(session.ladderReps.enumerated()), id: \.offset) { _, reps in
                        let h = max(4, CGFloat(reps) / 20.0 * 110)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(reps == 20 ? AppColors.ink : AppColors.ink3)
                            .frame(maxWidth: .infinity)
                            .frame(height: h)
                    }
                }
                .frame(height: 110, alignment: .bottom)
            }
        }
    }
```

- [ ] **Step 3: Build**

Run: `xcodebuild -scheme KB_Tracker -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD"`
Expected: `** BUILD SUCCEEDED **`. (`weightPhrase` and `mmss` already exist in this file and work for press.)

- [ ] **Step 4: Commit**

```bash
git add KB_Tracker/Views/WorkoutCompleteView.swift
git commit -m "Branch WorkoutCompleteView for press sessions"
```

---

## Task 7: History list + detail press branches

**Files:**
- Modify: `KB_Tracker/Views/HistoryView.swift`
- Modify: `KB_Tracker/Views/HistoryDetailView.swift`

First **read both files** to see the existing `fileprivate` row view (likely `SessionRow`) and the detail layout, then branch by `session.workoutType` following those patterns.

- [ ] **Step 1: Branch the history row by type**

In `HistoryView.swift`, inside the row view (e.g. `SessionRow`) where it currently renders the ABC mode/weight line + `<completed>/<target>` + `SparkBars(times:mode:)`, wrap in a type branch. ABC keeps its current rendering. For `.press`, render:

```swift
// Title line
Text("Press").font(.system(size: 16, weight: .bold)).foregroundColor(AppColors.ink)
  + Text("  \(session.weightDisplay)")  // adapt to the row's existing layout
// Sub line
Text("\(session.totalReps) reps · \(session.completedLadders) ladders")
    .font(.system(size: 12.5))
    .foregroundColor(AppColors.ink3)
// Micro spark of per-ladder reps (reuse SparkBars by mapping reps→Double seconds, rounds mode):
SparkBars(times: session.ladderReps.map { TimeInterval($0) }, mode: .rounds, height: 20, limit: 20)
    .frame(width: 60)
```

Match the row's existing date-block + chevron structure; only swap the middle text + spark when `session.workoutType == .press`. Keep ABC untouched.

- [ ] **Step 2: Branch the detail screen by type**

In `HistoryDetailView.swift`, branch the hero + stats + chart + per-set grid on `session.workoutType`. Keep the ABC path exactly as-is. For `.press`:
- Hero numeral: `Text("\(session.totalReps)")` with eyebrow `"PRESS · REPS"` + ` · \(session.weightDisplay.uppercased())`.
- Stat tiles: TOTAL REPS / LADDERS (`completedLadders`/`targetLadders`) / TIME (`mmss(totalDuration)`) / AVG·LADDER — mirror the `pressStatsGrid` math from Task 6 (avg = totalDuration / max(1, completedLadders)).
- Replace the per-set "EACH SET" grid with a per-ladder grid: for each `session.ladderReps` element, a tile with eyebrow `"L\(i+1, 2-digit)"` and value `"\(reps)"` (red via warn-style only if you want; full=20 normal).
- Keep the existing editable notes + delete `ConfirmSheet` unchanged (they're type-agnostic).

Reuse the file's existing `mmss` helper. If the detail file's stat/grid are private helper views, add `press`-prefixed siblings rather than overloading.

- [ ] **Step 3: Build**

Run: `xcodebuild -scheme KB_Tracker -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD"`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add KB_Tracker/Views/HistoryView.swift KB_Tracker/Views/HistoryDetailView.swift
git commit -m "Branch History list and detail for press sessions"
```

---

## Task 8: Full build, unit tests, and manual end-to-end verification

**Files:** none (verification only).

- [ ] **Step 1: Full unit-test run**

Run: `xcodebuild test -scheme KB_Tracker -destination 'platform=iOS Simulator,id=BC2D9E5A-17C6-4478-9F06-996326F22699' 2>&1 | tail -25`
Expected: all `PressLadderModelTests` (6) and `PressLadderViewModelTests` (7) PASS; build succeeds.

- [ ] **Step 2: Install + launch on the 26.2 simulator**

```bash
xcodebuild -scheme KB_Tracker -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath build/sim build 2>&1 | grep -E "error:|BUILD"
xcrun simctl boot BC2D9E5A-17C6-4478-9F06-996326F22699 2>/dev/null; true
xcrun simctl install BC2D9E5A-17C6-4478-9F06-996326F22699 build/sim/Build/Products/Debug-iphonesimulator/KB_Tracker.app
xcrun simctl launch BC2D9E5A-17C6-4478-9F06-996326F22699 aniche-studios.KB-Tracker
```

- [ ] **Step 3: Manual walk-through (screenshot each)**

Use `xcrun simctl io BC2D9E5A-17C6-4478-9F06-996326F22699 screenshot <path>` after each step (taps require the Simulator GUI — interact there):
1. Home → tap **WORKOUT = Press** → confirm LADDERS + LOAD dials and "Start · 5 ladders".
2. START → PressLadderView shows rung `2` highlighted, "0 total reps", LADDER 1/5.
3. Log rungs 2,3,5,10 → ladder advances to 2/5, total = 20; test **Undo last rung**.
4. Complete all 5 ladders → Complete shows "100 presses", LADDERS 5/5, TIME, ladder bar chart.
5. Save → History shows a **Press** row (reps · ladders + spark) in the same list as ABC.
6. Open it → per-ladder grid; delete via confirm sheet.
7. Switch WORKOUT back to **ABC**, run a short EMOM → confirm ABC flow + Complete still render unchanged.

- [ ] **Step 4: Final confirmation**

Confirm: build clean, 13 unit tests pass, press flow works end-to-end, ABC unchanged, existing saved sessions still load (default `.abc`). No further commit needed unless Step 3 surfaced a fix.

---

## Self-Review

- **Spec coverage:** run model (Task 3 VM + Task 4 view) ✓; Home top-level toggle (Task 5) ✓; WorkoutType discriminator + press fields + unified history (Tasks 1, 7) ✓; PressLadderViewModel separate from TimerViewModel (Task 3) ✓; default 5 ladders / Single 16 / fixed rungs (Tasks 5, 3) ✓; Complete branch (Task 6) ✓; History row + detail (Task 7) ✓; lightweight migration via defaulted properties (Task 1) ✓; undo affordance (Tasks 3, 4) ✓.
- **Deviation from spec (intentional):** audio cues live in the view (`onChange`), not the VM, to keep the VM purely unit-testable. Functionally equivalent.
- **Type consistency:** `WorkoutType`, `workoutType`, `targetLadders`, `ladderReps`, `totalReps`, `completedLadders`, `PressLadderViewModel.rungs`, `currentRungReps`, `logRung()`, `undoLastRung()`, `endEarly()`, `session`, `.press(kettlebellType:weight:targetLadders:)` are used identically across tasks and tests.
- **Placeholders:** Task 7 intentionally instructs reading the two history files first (their current private helpers weren't quoted here); the press-branch content is fully specified. All other tasks contain complete code.
