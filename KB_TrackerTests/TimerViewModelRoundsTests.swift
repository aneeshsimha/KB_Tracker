// TimerViewModelRoundsTests.swift
// KB_TrackerTests
//
// Characterization tests for TimerViewModel in Rounds mode.
// These pin CURRENT behavior — bugs and all. Do NOT change them to fix behavior;
// file an ANS ticket instead and see comments below.

import Testing
import Foundation
@testable import KB_Tracker

@MainActor
struct TimerViewModelRoundsTests {

    // MARK: 1 — Get-ready via fake clock

    /// A fake now that jumps 6 s per call causes a single tick to transition from
    /// getReady → working with go-beep and currentRound == 1.
    @Test func getReady_fakeClockJumps_transitionsToWorking() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 6.0)
        }

        let vm = TimerViewModel(config: config, audio: spy, now: fakeNow)
        // call 0 → getReadyStartTime = epoch+0
        vm.start()

        // call 1 → elapsed = 6 ≥ 5 → newCountdown = 0 → transition
        // call 2 → setStartTime = now() inside the transition
        vm.tick()

        #expect(vm.roundsPhase == .working)
        #expect(vm.currentRound == 1)
        #expect(spy.cues.contains("go"))
    }

    // MARK: 2 — Working phase accrues currentSetElapsed

    /// Each tick while in .working advances currentSetElapsed via now().timeIntervalSince(setStartTime).
    @Test func workingPhase_accruesCurrentSetElapsed() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        // Tick sequence for this test:
        //   call 0: start() → getReadyStartTime
        //   call 1: tick() getReady → elapsed=6 → transition, newCountdown=0
        //   call 2: setStartTime = now() inside transition = epoch+12
        //   calls 3+: handleRoundsWorking → now() for currentSetElapsed
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 6.0)
        }

        let vm = TimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()   // call 0
        vm.tick()    // calls 1 + 2: get-ready → working; setStartTime = epoch+12

        // call 3: now() = epoch+18; currentSetElapsed = 18 - 12 = 6
        vm.tick()
        #expect(vm.currentSetElapsed > 0)
        let elapsedAfterFirst = vm.currentSetElapsed

        // call 4: now() = epoch+24; currentSetElapsed = 24 - 12 = 12
        vm.tick()
        #expect(vm.currentSetElapsed > elapsedAfterFirst)
    }

    // MARK: 3 — Set-done before final round → resting

    /// handleRoundsSetDone() with rounds remaining transitions to .resting and
    /// initialises restCountdown to config.restDuration.
    @Test func setDone_beforeFinalRound_transitionsToResting() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 6.0)
        }

        let vm = TimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        vm.tick()  // → .working, round 1

        vm.handleRoundsSetDone()

        #expect(vm.roundsPhase == .resting)
        #expect(vm.restCountdown == 10)
    }

    // MARK: 4 — Rest countdown beeps at ≤5 s

    /// During rest, countdown beeps fire at restCountdown values 5, 4, 3, 2, 1
    /// (exactly 5 beeps, each fired once).
    @Test func restCountdown_beepsAtFiveToOne() {
        let spy = SpyAudioService()
        // Use restSeconds=10 so we can drive clock by 1 s increments easily
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        // We need fine-grained control over wall-clock time.
        // Plan:
        //   call 0: start() → getReadyStartTime = epoch+0
        //   call 1: tick() in getReady → elapsed = 6 ≥ 5 → transition
        //   call 2: setStartTime in getReady block = epoch+12 (unused, set done immediately)
        //   call 3: handleRoundsSetDone → setTime = now()-setStartTime (= 0, same epoch offset as we fix below)
        //   call 4: restStartTime = now() in handleRoundsSetDone
        //   calls 5+: tick() in resting phase → now() for elapsed
        //
        // For simplicity, freeze the working phase at a fixed time by using a
        // monotonically-increasing counter that steps 6 s (for get-ready), then 0 s
        // (for working so setTime = 0), then 1 s increments during rest.

        final class Clock {
            var callIdx = 0
            let epoch: Date
            init(epoch: Date) { self.epoch = epoch }
        }
        let clock = Clock(epoch: epoch)

        // Call mapping:
        //   0: start (getReady)             → epoch+0
        //   1: tick getReady elapsed check  → epoch+6
        //   2: setStartTime in getReady     → epoch+12 (working start)
        //   3: handleRoundsSetDone setTime  → epoch+12 (0s set time, same as start)
        //   4: restStartTime                → epoch+12
        //   5+: ticks in resting → epoch+12 + (callIdx-4)*1s
        let fakeNow: () -> Date = {
            defer { clock.callIdx += 1 }
            switch clock.callIdx {
            case 0: return epoch
            case 1: return epoch.addingTimeInterval(6)
            case 2: return epoch.addingTimeInterval(12)
            case 3: return epoch.addingTimeInterval(12)  // set done at same time as start
            case 4: return epoch.addingTimeInterval(12)  // restStartTime
            default:
                // Each subsequent call advances 1 second from rest start (epoch+12)
                let restElapsed = Double(clock.callIdx - 4)
                return epoch.addingTimeInterval(12 + restElapsed)
            }
        }

        let vm = TimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()   // call 0
        vm.tick()    // calls 1, 2 → working, round 1
        vm.handleRoundsSetDone()  // calls 3, 4 → resting, restCountdown=10

        // At this point restCountdown == 10, no beeps yet
        let cusBefore = spy.cues.filter { $0 == "countdown" }.count

        // Tick through rest: each tick→call advances 1 s.
        // restStartTime = epoch+12.
        // call 5: elapsed=1s → newCountdown=9 (no beep)
        // call 6: elapsed=2 → 8, call 7: 3→7, call 8: 4→6, call 9: 5→5 (BEEP)
        // call 10: 6→4 (BEEP), call 11: 7→3 (BEEP), call 12: 8→2 (BEEP), call 13: 9→1 (BEEP)
        // call 14: 10→0 → transitionToNextRound
        for _ in 0..<10 { vm.tick() }  // drives clock through calls 5..14

        let countdownBeeps = spy.cues.filter { $0 == "countdown" }.count - cusBefore
        #expect(countdownBeeps == 5)
    }

    // MARK: 5 — Rest hitting 0 auto-transitions with go-beep

    /// When restCountdown reaches 0, transitionToNextRound() fires: roundsPhase → .working,
    /// currentRound increments, and a go-beep plays.
    @Test func restHittingZero_autoTransitionsToWorking() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)

        final class Clock { var callIdx = 0 }
        let clock = Clock()
        let fakeNow: () -> Date = {
            defer { clock.callIdx += 1 }
            switch clock.callIdx {
            case 0: return epoch
            case 1: return epoch.addingTimeInterval(6)    // get-ready elapsed
            case 2: return epoch.addingTimeInterval(12)   // setStartTime
            case 3: return epoch.addingTimeInterval(12)   // setDone measure
            case 4: return epoch.addingTimeInterval(12)   // restStartTime
            default:
                let restElapsed = Double(clock.callIdx - 4)
                return epoch.addingTimeInterval(12 + restElapsed)
            }
        }

        let vm = TimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        vm.tick()
        vm.handleRoundsSetDone()  // → resting, round 1

        // Drive 10 ticks: at elapsed=10s, restCountdown→0 → transition
        for _ in 0..<11 { vm.tick() }

        #expect(vm.roundsPhase == .working)
        #expect(vm.currentRound == 2)
        let goBeeps = spy.cues.filter { $0 == "go" }.count
        // First go was from get-ready, second from rest→working transition
        #expect(goBeeps == 2)
    }

    // MARK: 6 — skipRest() transitions immediately

    /// Calling skipRest() during rest immediately fires transitionToNextRound():
    /// roundsPhase → .working and a go-beep fires.
    @Test func skipRest_transitionsImmediatelyToWorking() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 6.0)
        }

        let vm = TimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        vm.tick()               // → .working round 1
        vm.handleRoundsSetDone()  // → .resting

        let goBefore = spy.cues.filter { $0 == "go" }.count

        vm.skipRest()

        #expect(vm.roundsPhase == .working)
        #expect(vm.currentRound == 2)
        let goAfter = spy.cues.filter { $0 == "go" }.count
        #expect(goAfter == goBefore + 1)
    }

    // MARK: 7 — Final set-done → complete + session

    /// handleRoundsSetDone() on the last round transitions to .complete, plays
    /// completion sound, and populates completedSession.
    @Test func finalSetDone_completesWorkout() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 1.0)
        }

        let vm = TimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        // Drive through get-ready — need elapsed ≥ 5 s.
        // With 1 s per call: call 0=0s, call 1=1s, ..., call 5=5s
        // getReadyStartTime = epoch+0 (call 0)
        // tick 1: now()=epoch+1, elapsed=1 → newCountdown=4 (beep), no transition
        // tick 2: now()=epoch+2, elapsed=2 → newCountdown=3 (beep)
        // tick 3: now()=epoch+3, elapsed=3 → newCountdown=2 (beep)
        // tick 4: now()=epoch+4, elapsed=4 → newCountdown=1 (beep)
        // tick 5: now()=epoch+5, elapsed=5 → newCountdown=0 → playGoBeep, phase=.working
        //   setStartTime = now() (call 6)
        for _ in 0..<5 { vm.tick() }
        #expect(vm.roundsPhase == .working)
        #expect(vm.currentRound == 1)

        // Complete round 1 → resting
        vm.handleRoundsSetDone()
        #expect(vm.roundsPhase == .resting)

        // Skip rest → round 2 working
        vm.skipRest()
        #expect(vm.currentRound == 2)

        // Complete round 2 → resting
        vm.handleRoundsSetDone()
        #expect(vm.roundsPhase == .resting)

        // Skip rest → round 3 working
        vm.skipRest()
        #expect(vm.currentRound == 3)

        // Complete final round → complete
        vm.handleRoundsSetDone()

        #expect(vm.roundsPhase == .complete)
        #expect(spy.cues.contains("completion"))

        let session = vm.completedSession
        #expect(session != nil)
        #expect(session?.completedRounds == 3)
        #expect(session?.isCompleted == true)
        #expect(session?.setTimes.count == 3)
    }

    // MARK: — Behavioral oddities pinned as-is (for ANS-144)

    /// NOTE: pinning as-is — fix target in ANS-144.
    /// handleRoundsGetReady uses `newCountdown != getReadyCountdown` as a change-guard,
    /// so beeps only fire when the countdown *changes*. If two consecutive calls to now()
    /// return the same second (e.g. elapsed stays at 4s for two ticks), no duplicate beep fires.
    /// This is correct deduplication behavior, but it means beep count depends on the clock,
    /// not on tick count.
    @Test func behavioralOddity_getReady_beepsOnClockChangeNotTick() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        // Fake clock that advances 1s each call
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 1.0)
        }

        let vm = TimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()   // call 0
        // Each tick advances 1s: countdowns go 4,3,2,1,0→transition
        // 4 countdown beeps + 1 go beep
        for _ in 0..<5 { vm.tick() }

        let countdowns = spy.cues.filter { $0 == "countdown" }.count
        // NOTE: Only 4 countdown beeps fire because the first tick changes countdown 5→4
        // (not from the initial 5, but the first *change* is when elapsed passes 1s).
        // Specifically: getReadyCountdown starts at 5. tick 1: elapsed=1, newCountdown=4,
        // 4 != 5 → beep. So 4 beeps for seconds 4,3,2,1.
        // NOTE: pinning as-is — the get-ready in Rounds mode fires only 4 countdown beeps
        // (not 5 like EMOM mode), because it detects countdown *changes* not absolute values.
        #expect(countdowns == 4)
        #expect(spy.cues.filter { $0 == "go" }.count == 1)
    }

    /// NOTE: pinning as-is — fix target in ANS-144.
    /// currentSetElapsed is reset to 0 in transitionToNextRound() but setStartTime is set to
    /// now() simultaneously. The first tick after transitioning will set currentSetElapsed
    /// to now()-setStartTime, which may be non-zero if the clock has advanced.
    @Test func behavioralOddity_currentSetElapsedResetOnTransition() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 10)

        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callIdx = 0
        let fakeNow: () -> Date = {
            defer { callIdx += 1 }
            return epoch.addingTimeInterval(Double(callIdx) * 6.0)
        }

        let vm = TimerViewModel(config: config, audio: spy, now: fakeNow)
        vm.start()
        vm.tick()               // → working round 1
        vm.handleRoundsSetDone()  // → resting
        vm.skipRest()            // → working round 2, currentSetElapsed = 0

        // Immediately after skipRest, currentSetElapsed should be 0
        #expect(vm.currentSetElapsed == 0)
    }
}
