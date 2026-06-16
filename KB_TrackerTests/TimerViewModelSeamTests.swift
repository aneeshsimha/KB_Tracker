// TimerViewModelSeamTests.swift
// KB_Tracker
//
// Smoke tests proving the tick() seam and now provider are wired up correctly.
// These tests drive TimerViewModel without any real timers or sleeps.

import Testing
import Foundation
@testable import KB_Tracker

@MainActor
struct TimerViewModelSeamTests {

    // MARK: - Smoke Tests

    /// tick() drives EMOM getReady phase: totalElapsed accumulates without real time passing.
    @Test func emomTickAccumulatesElapsed() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 5)
        // now() is not consulted during EMOM getReady (uses totalElapsed accumulation)
        let vm = TimerViewModel(config: config, audio: spy, now: Date.init)

        vm.start()

        // Drive 5 ticks (each += 0.1 in handleEMOMGetReady)
        for _ in 0..<5 {
            vm.tick()
        }

        // totalElapsed should be ~0.5 (5 × 0.1)
        #expect(vm.totalElapsed > 0.4 && vm.totalElapsed < 0.6)
        #expect(vm.emomPhase == .getReady)
    }

    /// tick() transitions EMOM from getReady to active after enough ticks.
    /// WorkoutParameters.getReadySeconds == 5, so need 51 ticks to accumulate ≥5.0
    @Test func emomTickTransitionsToActive() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 5)
        let vm = TimerViewModel(config: config, audio: spy, now: Date.init)

        vm.start()

        // 51 ticks × 0.1 = 5.1 ≥ getReadySeconds(5) → transitions to active
        for _ in 0..<51 {
            vm.tick()
        }

        #expect(vm.emomPhase == .active)
        #expect(vm.currentRound == 1)
        #expect(spy.cues.contains("go"))
    }

    /// Rounds mode: injecting a fake now that jumps forward enough to skip getReady
    /// in a single tick, verifying the seam is wired end-to-end.
    @Test func roundsFakeNowDrivesGetReadyTransition() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 3, restSeconds: 60)

        // Fake clock: advances 6 seconds per call so the first tick sees elapsed ≥ getReadySeconds(5)
        let epoch = Date(timeIntervalSince1970: 1_000_000)
        var callCount = 0
        let fakeNow: () -> Date = {
            defer { callCount += 1 }
            return epoch.addingTimeInterval(Double(callCount) * 6.0)
        }

        let vm = TimerViewModel(config: config, audio: spy, now: fakeNow)
        // start() → getReadyStartTime = epoch (callCount 0 → addingTimeInterval(0))
        vm.start()

        // First tick: now() returns epoch+6 → elapsed = 6 ≥ 5 → transitions to working
        vm.tick()

        #expect(vm.roundsPhase == .working)
        #expect(vm.currentRound == 1)
        #expect(spy.cues.contains("go"))
    }
}
