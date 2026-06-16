// EMOMTimerViewModelEdgeCaseTests.swift
// KB_TrackerTests
//
// Edge case tests for EMOMTimerViewModel — guards, no-ops, beep idempotence,
// and partial save with 0 rounds. These complement the characterization suite
// in EMOMTimerViewModelTests.swift and do NOT modify it.

import Testing
import Foundation
@testable import KB_Tracker

@MainActor
struct EMOMTimerViewModelEdgeCaseTests {

    // MARK: 1 — setDone() double-tap is a no-op

    /// Calling setDone() twice: second call is a no-op because isSetInProgress == false
    /// after the first. setTimes.count must be 1, not 2.
    @Test func setDoneDoubleTap_secondCallIsNoOp() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        vm.start()
        // Drive through get-ready into active (round 1, isSetInProgress == true)
        for _ in 0..<51 { vm.tick() }

        #expect(vm.isSetInProgress == true)

        vm.setDone()
        #expect(vm.setTimes.count == 1)
        #expect(vm.isSetInProgress == false)

        vm.setDone()  // second tap — should be ignored
        #expect(vm.setTimes.count == 1)
    }

    // MARK: 2 — setDone() before start does nothing

    /// Calling setDone() before start() (while in .getReady) is a no-op.
    /// setTimes stays empty.
    @Test func setDoneBeforeStart_isNoOp() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        // Do NOT call start() or tick() — still in .getReady with isSetInProgress == false
        #expect(vm.emomPhase == .getReady)
        #expect(vm.isSetInProgress == false)

        vm.setDone()

        #expect(vm.setTimes.isEmpty)
    }

    // MARK: 3 — setDone() while in .getReady phase does nothing

    /// Calling setDone() while ticking in .getReady (before the active transition)
    /// is a no-op because isSetInProgress is false.
    @Test func setDoneDuringGetReady_isNoOp() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        vm.start()
        // Advance a few ticks — still in get-ready, not yet active
        for _ in 0..<10 { vm.tick() }

        #expect(vm.emomPhase == .getReady)

        vm.setDone()

        #expect(vm.setTimes.isEmpty)
    }

    // MARK: 4 — setDone() in .complete phase does nothing

    /// After the workout completes, calling setDone() is a no-op.
    /// setTimes.count stays at the final count (3 for a 3-minute EMOM).
    @Test func setDoneAfterComplete_isNoOp() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 0.0)
        }

        let vm = EMOMTimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        for _ in 0..<51 { vm.tick() }  // → active, round 1

        // Complete all 3 rounds via minute boundaries
        vm.setDone()
        for _ in 0..<601 { vm.tick() }  // → round 2
        vm.setDone()
        for _ in 0..<601 { vm.tick() }  // → round 3
        vm.setDone()                    // final setDone → .complete

        #expect(vm.emomPhase == .complete)
        let countAfterComplete = vm.setTimes.count

        vm.setDone()  // tap after complete — should be ignored

        #expect(vm.setTimes.count == countAfterComplete)
    }

    // MARK: 5 — Beep idempotence: two ticks in same integer second → one beep

    /// Two consecutive ticks where secondsIntoMinute stays within the same integer second
    /// (e.g. both map to secondsIntoMinute ∈ [55.0, 56.0)) must produce exactly one
    /// countdown beep, not two. The lastBeepSecond guard prevents duplicates.
    @Test func beepIdempotence_twoTicksSameSecond_oneBeep() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        vm.start()
        for _ in 0..<51 { vm.tick() }  // → active, round 1
        vm.setDone()                    // isSetInProgress = false so boundary advances normally

        // Advance to 54.9 s into the minute (549 ticks × 0.1 s)
        for _ in 0..<549 { vm.tick() }

        let cusBefore = spy.cues.filter { $0 == "countdown" }.count

        // Two ticks that both land in the same integer second at the :55 mark.
        // First tick: secondsIntoMinute goes from 54.9 → 55.0; Int(55.0) = 55.
        //   secondsRemaining = 60 - 55 = 5 → beepSecond = 55 → fires beep, lastBeepSecond = 55
        // Second tick: secondsIntoMinute → 55.1; Int(55.1) = 55 → same beepSecond → guarded out.
        vm.tick()
        vm.tick()

        let cusAfter = spy.cues.filter { $0 == "countdown" }.count
        #expect(cusAfter - cusBefore == 1)
    }

    // MARK: 6 — savePartialWorkout() in get-ready phase

    /// Calling savePartialWorkout() before any rounds complete produces a partialSession
    /// with completedRounds == 0 and setTimes.isEmpty == true.
    @Test func savePartialWorkout_inGetReady_zeroRounds() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        vm.start()
        // Tick a few times but stay in get-ready
        for _ in 0..<10 { vm.tick() }

        #expect(vm.emomPhase == .getReady)

        vm.savePartialWorkout()

        let partial = vm.partialSession
        #expect(partial != nil)
        #expect(partial?.completedRounds == 0)
        #expect(partial?.setTimes.isEmpty == true)
        #expect(partial?.isCompleted == false)
    }

    // MARK: 7 — stop() then tick() doesn't crash or corrupt phase

    /// After stop() is called, a subsequent tick() executes phase logic safely —
    /// it doesn't check timer state, so it's not a crash risk. Verify no crash
    /// and that the phase hasn't changed unexpectedly.
    @Test func stopThenTick_doesNotCrashOrCorruptPhase() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        vm.start()
        for _ in 0..<51 { vm.tick() }  // → active, round 1
        #expect(vm.emomPhase == .active)

        vm.stop()
        let phaseBefore = vm.emomPhase

        // This should not crash; tick() directly executes phase logic regardless of timer state
        vm.tick()

        // Phase should remain .active (no unexpected transition from a single tick)
        #expect(vm.emomPhase == phaseBefore)
    }
}
