// RoundsTimerViewModelEdgeCaseTests.swift
// KB_TrackerTests
//
// Edge case tests for RoundsTimerViewModel — guards, no-ops in wrong phases,
// beep idempotence, and partial save with 0 rounds. These complement the
// characterization suite in RoundsTimerViewModelTests.swift and do NOT modify it.

import Testing
import Foundation
@testable import KB_Tracker

@MainActor
struct RoundsTimerViewModelEdgeCaseTests {

    // MARK: 1 — setDone() in .getReady phase is a no-op

    /// setDone() is guarded by `roundsPhase == .working`.
    /// Calling it during get-ready must not append to setTimes.
    @Test func setDone_inGetReady_isNoOp() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 0.1)
        }

        let vm = RoundsTimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()  // still in .getReady

        #expect(vm.roundsPhase == .getReady)

        vm.setDone()

        #expect(vm.setTimes.isEmpty)
        #expect(vm.roundsPhase == .getReady)
    }

    // MARK: 2 — setDone() in .resting phase is a no-op

    /// After one set is done (transitioning to .resting), a second setDone() call
    /// is a no-op because the guard requires roundsPhase == .working.
    @Test func setDone_inResting_isNoOp() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 6.0)
        }

        let vm = RoundsTimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        vm.tick()    // → .working round 1
        vm.setDone() // → .resting, setTimes.count == 1

        #expect(vm.roundsPhase == .resting)
        #expect(vm.setTimes.count == 1)

        vm.setDone()  // no-op in .resting

        #expect(vm.setTimes.count == 1)
        #expect(vm.roundsPhase == .resting)
    }

    // MARK: 3 — setDone() in .complete phase is a no-op

    /// After the workout completes, setDone() is a no-op.
    /// setTimes.count stays at the final round count.
    @Test func setDone_inComplete_isNoOp() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 1.0)
        }

        let vm = RoundsTimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        // Drive get-ready (1 s/call: 5 ticks advance countdown 5→4→3→2→1→0 → .working)
        for _ in 0..<5 { vm.tick() }
        #expect(vm.roundsPhase == .working)

        // Round 1 → resting → round 2
        vm.setDone()
        vm.skipRest()
        // Round 2 → resting → round 3
        vm.setDone()
        vm.skipRest()
        // Round 3 → complete
        vm.setDone()

        #expect(vm.roundsPhase == .complete)
        let countAfterComplete = vm.setTimes.count

        vm.setDone()  // no-op after complete

        #expect(vm.setTimes.count == countAfterComplete)
        #expect(vm.roundsPhase == .complete)
    }

    // MARK: 4 — setDone() double-tap while working is a no-op

    /// The second setDone() call is a no-op because phase is now .resting.
    @Test func setDoneDoubleTap_whileWorking_secondIsNoOp() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 6.0)
        }

        let vm = RoundsTimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        vm.tick()    // → .working round 1

        vm.setDone()  // first tap → .resting, setTimes.count == 1
        #expect(vm.roundsPhase == .resting)
        #expect(vm.setTimes.count == 1)

        vm.setDone()  // second tap → no-op (phase is .resting)
        #expect(vm.setTimes.count == 1)
        #expect(vm.roundsPhase == .resting)
    }

    // MARK: 5a — skipRest() while working is a no-op (bug fix: ANS-144)

    /// skipRest() used to have no phase guard and would call transitionToNextRound()
    /// from any phase. Now it must guard `roundsPhase == .resting`.
    /// Calling skipRest() while in .working must be a no-op.
    @Test func skipRest_whileWorking_isNoOp() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 6.0)
        }

        let vm = RoundsTimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        vm.tick()  // → .working round 1

        #expect(vm.roundsPhase == .working)
        #expect(vm.currentRound == 1)

        let goBefore = spy.cues.filter { $0 == "go" }.count

        vm.skipRest()  // must be a no-op — phase is .working, not .resting

        #expect(vm.roundsPhase == .working)
        #expect(vm.currentRound == 1)
        // No extra go-beep should fire
        #expect(spy.cues.filter { $0 == "go" }.count == goBefore)
    }

    // MARK: 5b — skipRest() in .getReady is a no-op

    @Test func skipRest_inGetReady_isNoOp() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 0.1)
        }

        let vm = RoundsTimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()  // still in .getReady

        #expect(vm.roundsPhase == .getReady)

        vm.skipRest()  // must be a no-op

        #expect(vm.roundsPhase == .getReady)
        #expect(vm.currentRound == 0)
        #expect(spy.cues.filter { $0 == "go" }.isEmpty)
    }

    // MARK: 5c — skipRest() in .complete is a no-op

    @Test func skipRest_inComplete_isNoOp() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 1.0)
        }

        let vm = RoundsTimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        for _ in 0..<5 { vm.tick() }  // → .working round 1

        vm.setDone(); vm.skipRest()  // round 2
        vm.setDone(); vm.skipRest()  // round 3
        vm.setDone()                  // → .complete

        #expect(vm.roundsPhase == .complete)
        let roundsBefore = vm.currentRound
        let goBefore = spy.cues.filter { $0 == "go" }.count

        vm.skipRest()  // must be a no-op

        #expect(vm.roundsPhase == .complete)
        #expect(vm.currentRound == roundsBefore)
        #expect(spy.cues.filter { $0 == "go" }.count == goBefore)
    }

    // MARK: 6 — savePartialWorkout() before any rounds

    /// Calling savePartialWorkout() in .getReady (no rounds completed) produces a
    /// partialSession with completedRounds == 0 and setTimes.isEmpty == true.
    @Test func savePartialWorkout_beforeAnyRounds_zeroRounds() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 0.1)
        }

        let vm = RoundsTimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        // A few ticks in .getReady
        for _ in 0..<5 { vm.tick() }

        #expect(vm.roundsPhase == .getReady)

        vm.savePartialWorkout()

        let partial = vm.partialSession
        #expect(partial != nil)
        #expect(partial?.completedRounds == 0)
        #expect(partial?.setTimes.isEmpty == true)
        #expect(partial?.isCompleted == false)
    }

    // MARK: 7 — Rest beep idempotence: two ticks where restCountdown doesn't change → no duplicate

    /// The `newCountdown != restCountdown` guard in handleRoundsResting() prevents duplicate
    /// beeps when the clock doesn't advance a full second between ticks.
    /// Two ticks that read the same restCountdown value must produce exactly one beep.
    @Test func restBeepIdempotence_twoTicksSameCountdown_oneBeep() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)

        // Controlled clock:
        //   call 0: start() → getReadyStartTime = epoch+0
        //   call 1: tick() getReady elapsed check → epoch+6 (triggers transition)
        //   call 2: setStartTime inside getReady block → epoch+6
        //   call 3: setDone() setTime measure → epoch+6
        //   call 4: restStartTime → epoch+6
        //   call 5: first resting tick → epoch+11 (elapsed=5 → newCountdown=5, BEEP, fires once)
        //   call 6: second resting tick → epoch+11 (SAME time, newCountdown=5, no change → no beep)
        final class Clock { var callIdx = 0 }
        let clock = Clock()
        let fakeNow: () -> Date = {
            defer { clock.callIdx += 1 }
            switch clock.callIdx {
            case 0: return epoch
            case 1: return epoch.addingTimeInterval(6)
            case 2: return epoch.addingTimeInterval(6)
            case 3: return epoch.addingTimeInterval(6)
            case 4: return epoch.addingTimeInterval(6)
            case 5: return epoch.addingTimeInterval(11)  // restElapsed=5 → countdown=5
            case 6: return epoch.addingTimeInterval(11)  // same second — guard fires
            default: return epoch.addingTimeInterval(11)
            }
        }

        let vm = RoundsTimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()   // call 0
        vm.tick()    // calls 1, 2 → .working round 1
        vm.setDone() // calls 3, 4 → .resting, restCountdown=10

        let cusBefore = spy.cues.filter { $0 == "countdown" }.count

        // Two ticks that both see restCountdown at 5:
        //   tick call 5 → newCountdown=5 != restCountdown(10) → fires beep, sets restCountdown=5
        //   tick call 6 → newCountdown=5 == restCountdown(5) → no change → no beep
        vm.tick()  // call 5 — beep fires
        vm.tick()  // call 6 — guard prevents duplicate

        let cusAfter = spy.cues.filter { $0 == "countdown" }.count
        #expect(cusAfter - cusBefore == 1)
    }
}
