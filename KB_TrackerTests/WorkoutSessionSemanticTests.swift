// WorkoutSessionSemanticTests.swift
// KB_TrackerTests
//
// Tests for the targetMinutes semantic accessor on WorkoutSession and WorkoutConfig.

import Testing
@testable import KB_Tracker

struct WorkoutSessionSemanticTests {

    // WorkoutSession.targetMinutes reads the same value as targetRounds
    @Test func targetMinutesGetReadsTargetRounds() {
        let session = WorkoutSession(
            mode: .emom,
            kettlebellType: .double,
            weight: 20,
            targetRounds: 15
        )
        #expect(session.targetMinutes == 15)
        #expect(session.targetMinutes == session.targetRounds)
    }

    // WorkoutSession.targetMinutes setter writes through to targetRounds
    @Test func targetMinutesSetWritesTargetRounds() {
        let session = WorkoutSession(
            mode: .emom,
            kettlebellType: .double,
            weight: 20,
            targetRounds: 20
        )
        session.targetMinutes = 30
        #expect(session.targetRounds == 30)
    }

    // roundsDisplay uses the stored targetRounds for both modes
    @Test func roundsDisplayUsesTargetRoundsForBothModes() {
        let emomSession = WorkoutSession(
            mode: .emom,
            kettlebellType: .double,
            weight: 20,
            targetRounds: 20
        )
        emomSession.completedRounds = 18
        #expect(emomSession.roundsDisplay == "18/20")

        let roundsSession = WorkoutSession(
            mode: .rounds,
            kettlebellType: .single,
            weight: 16,
            targetRounds: 10
        )
        roundsSession.completedRounds = 7
        #expect(roundsSession.roundsDisplay == "7/10")
    }

    // WorkoutConfig.targetMinutes getter returns targetRounds for EMOM configs
    @Test func configTargetMinutesMatchesEmomMinutesParam() {
        let config = WorkoutConfig.emom(kettlebellType: .double, weight: 20, minutes: 25)
        #expect(config.targetMinutes == 25)
        #expect(config.targetMinutes == config.targetRounds)
    }
}
