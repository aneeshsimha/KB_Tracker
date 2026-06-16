// EMOMTimerViewModelTests.swift
// KB_TrackerTests
//
// Ported from TimerViewModelEMOMTests.swift — tests the new EMOMTimerViewModel.
// These pin the same behavior as the originals. Do NOT change them to fix behavior;
// file an ANS ticket instead.

import Testing
import Foundation
@testable import KB_Tracker

// MARK: - Helpers

/// Drive EMOM from getReady into active phase (51 ticks = 5.1 s of totalElapsed).
/// NOTE: tick 50 brings totalElapsed to exactly 5.0 which satisfies >= 5.0.
/// We use 51 to avoid floating-point edge sensitivity.
@MainActor
private func driveEMOMGetReadyToActive(_ vm: EMOMTimerViewModel) {
    for _ in 0..<51 { vm.tick() }
}

@MainActor
struct EMOMTimerViewModelTests {

    // MARK: 1 — Get-ready countdown

    /// During the 5-second get-ready, exactly 5 countdown beeps fire (one per elapsed
    /// second, at seconds 0–4), followed by a go-beep on transition, then emomPhase == .active
    /// and currentRound == 1.
    @Test func getReadyCountdown_fiveBeepsThenGoBeepThenActive() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        vm.start()
        driveEMOMGetReadyToActive(vm)

        // 5 countdown beeps (seconds 0–4) + 1 go-beep on transition
        let countdowns = spy.cues.filter { $0 == "countdown" }
        let gos = spy.cues.filter { $0 == "go" }
        #expect(countdowns.count == 5)
        #expect(gos.count == 1)
        // go-beep comes after the 5 countdown beeps
        #expect(spy.cues.last == "go")

        #expect(vm.emomPhase == .active)
        #expect(vm.currentRound == 1)
    }

    // MARK: 2 — Set-done records setTimes from injected clock

    /// setDone() appends now()-setStartTime to setTimes.
    /// We inject a fake clock: call 0 → start(), call 1 → startNewEMOMRound() (setStartTime),
    /// call 2 → setDone() (now()).  Delta = 30 s.
    @Test func setDoneRecordsSetTimeFromInjectedClock() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        // Timestamps returned in sequence:
        //   call 0: startNewEMOMRound() inside transition → setStartTime = epoch+0
        //   call 1: setDone() → now() = epoch+30 → setDuration = 30
        let times: [TimeInterval] = [0, 30]
        var callIdx = 0
        let fakeNow: () -> Date = {
            let t = times[min(callIdx, times.count - 1)]
            callIdx += 1
            return epoch.addingTimeInterval(t)
        }

        let vm = EMOMTimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        driveEMOMGetReadyToActive(vm)  // triggers startNewEMOMRound() → call 0

        vm.setDone()  // → call 1

        #expect(vm.setTimes.count == 1)
        #expect(vm.setTimes[0] == 30.0)
    }

    // MARK: 3 — Minute boundary when set is done

    /// When secondsIntoMinute reaches ≥60 and isSetInProgress == false, a new round
    /// starts and a go-beep fires.
    @Test func minuteBoundary_setDone_startsNewRound() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        vm.start()
        driveEMOMGetReadyToActive(vm)
        // Now in round 1, isSetInProgress == true

        // Mark set done so boundary triggers new round (not overtime)
        vm.setDone()
        #expect(vm.isSetInProgress == false)

        let roundBefore = vm.currentRound  // 1
        let goBefore = spy.cues.filter { $0 == "go" }.count  // 1 from get-ready transition

        // Drive 601 ticks from start of active phase to reach secondsIntoMinute ≥ 60
        for _ in 0..<601 { vm.tick() }

        #expect(vm.currentRound == roundBefore + 1)
        let goAfter = spy.cues.filter { $0 == "go" }.count
        #expect(goAfter == goBefore + 1)
        #expect(vm.emomPhase == .active)
    }

    // MARK: 4 — Minute boundary when set is NOT done → overtime

    /// When secondsIntoMinute > 60 and isSetInProgress == true, isOvertime becomes true.
    /// NOTE: the condition is strict `> 60` (not `>= 60`), so at exactly 60.0 isOvertime is false.
    /// NOTE: pinning as-is — fix target in ANS-144.
    /// countdownSeconds uses Int(secondsIntoMinute), so at 60.1 s it returns 0 (Int(60.1)=60,
    /// 60-60=0). countdownSeconds only becomes > 0 once secondsIntoMinute >= 61.0 (1010 ticks).
    @Test func minuteBoundary_setNotDone_isOvertime() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        vm.start()
        driveEMOMGetReadyToActive(vm)
        // isSetInProgress == true (set NOT done)

        // Drive just past 60 s: 601 ticks puts secondsIntoMinute at ~60.1
        for _ in 0..<601 { vm.tick() }

        // NOTE: boundary guard `!isSetInProgress` is false, so no round transition fires.
        // secondsIntoMinute keeps accumulating past 60.
        #expect(vm.isSetInProgress == true)
        #expect(vm.isOvertime == true)
        // NOTE: pinning as-is — at 60.1 s, Int(60.1)=60, so countdownSeconds = 60-60 = 0
        // even though isOvertime is true. countdownSeconds only turns > 0 once Int(secondsIntoMinute) > 60.
        #expect(vm.countdownSeconds == 0)

        // Drive 10 more ticks (to ~61.1 s) to confirm countdownSeconds eventually goes > 0
        for _ in 0..<10 { vm.tick() }
        #expect(vm.countdownSeconds > 0)
    }

    // MARK: 5 — Countdown beeps :55–:59

    /// Exactly 5 countdown beeps fire in the window secondsIntoMinute ∈ [55, 60), one per second.
    @Test func activePhase_countdownBeepsFiveToOne() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        vm.start()
        driveEMOMGetReadyToActive(vm)

        // Mark set done so we don't hit overtime path
        vm.setDone()

        // Advance to just before :55 (549 ticks = 54.9 s)
        for _ in 0..<549 { vm.tick() }

        let cusBefore = spy.cues.filter { $0 == "countdown" }.count

        // Drive through the :55-:59 window (50 ticks = 5 s worth, each second fires once)
        for _ in 0..<50 { vm.tick() }

        let countdownsInWindow = spy.cues.filter { $0 == "countdown" }.count - cusBefore
        #expect(countdownsInWindow == 5)
    }

    // MARK: 6 — Final round completion

    /// After completing all rounds (3-minute EMOM), emomPhase == .complete, completion sound
    /// fires, and completedSession is populated with correct data.
    @Test func finalRoundCompletion_emomComplete() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        // We need enough calls: start(), then startNewEMOMRound() x3, setDone() x3
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 0.0)  // all at epoch — we just need it to not crash
        }

        let vm = EMOMTimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()

        // Helper: complete a round by marking set done, then driving past minute boundary
        func completeRound() {
            vm.setDone()
            for _ in 0..<601 { vm.tick() }
        }

        // Drive to active (round 1)
        driveEMOMGetReadyToActive(vm)

        // Round 1: mark done, drive to boundary → starts round 2
        completeRound()
        #expect(vm.currentRound == 2)

        // Round 2: mark done, drive to boundary → starts round 3
        completeRound()
        #expect(vm.currentRound == 3)

        // Round 3: mark set done — this triggers completeWorkout() via setDone
        // because currentRound (3) >= config.targetMinutes (3)
        vm.setDone()

        #expect(vm.emomPhase == .complete)
        #expect(spy.cues.contains("completion"))
        let session = vm.completedSession
        #expect(session != nil)
        #expect(session?.completedRounds == 3)
        #expect(session?.isCompleted == true)
        #expect(session?.setTimes.count == 3)
    }

    // MARK: 7 — savePartialWorkout mid-round

    /// Calling savePartialWorkout() during an active round populates partialSession
    /// with isCompleted == false.
    @Test func savePartialWorkout_midRound_populatesPartialSession() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        vm.start()
        driveEMOMGetReadyToActive(vm)

        // Advance 30 ticks into round 1 (3 s elapsed)
        for _ in 0..<30 { vm.tick() }

        vm.savePartialWorkout()

        let partial = vm.partialSession
        #expect(partial != nil)
        #expect(partial?.isCompleted == false)
        #expect(partial?.completedRounds == 1)
        #expect(partial?.setTimes.isEmpty == true)
    }

    // MARK: — Behavioral oddities pinned as-is (for ANS-144)

    /// NOTE: pinning as-is — fix target in ANS-144.
    /// After get-ready transitions to active, `lastBeepSecond` is 4 (from the last countdown
    /// beep at second 4). The active-phase countdown beep deduplication uses the same field.
    /// This means the very first active-phase beep at beepSecond==55 is NOT suppressed,
    /// but it does mean the state is "polluted" at the round start.
    @Test func behavioralOddity_lastBeepSecondCarriedAcrossPhases() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        vm.start()
        driveEMOMGetReadyToActive(vm)

        // 5 countdown + 1 go → total 6 cues, go is last
        #expect(spy.cues.count == 6)
        #expect(spy.cues == ["countdown", "countdown", "countdown", "countdown", "countdown", "go"])
    }

    /// NOTE: pinning as-is — fix target in ANS-144.
    /// setDone() also completes the workout when currentRound >= targetMinutes,
    /// regardless of secondsIntoMinute. This means the last round can complete early
    /// (before the minute boundary) via the set-done path.
    @Test func behavioralOddity_setDoneOnLastRoundCompletesEarly() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 3)
        let vm = EMOMTimerViewModel(config: config, audio: spy)

        vm.start()
        driveEMOMGetReadyToActive(vm)

        // Complete rounds 1 and 2 via minute boundary
        vm.setDone()
        for _ in 0..<601 { vm.tick() }
        vm.setDone()
        for _ in 0..<601 { vm.tick() }

        // Round 3: mark done IMMEDIATELY (e.g. at :01 into the minute)
        // → completeWorkout() fires without waiting for the minute to expire
        vm.setDone()
        #expect(vm.emomPhase == .complete)
    }
}
