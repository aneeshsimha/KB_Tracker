import Testing
import Foundation
@testable import KB_Tracker

struct WorkoutConfigTests {

    // MARK: - emom factory

    @Test func emomFactoryModeIsEMOM() {
        let c = WorkoutConfig.emom(kettlebellType: .double, weight: 20, minutes: 20)
        #expect(c.mode == .emom)
    }

    @Test func emomFactoryWorkoutTypeIsABC() {
        let c = WorkoutConfig.emom(kettlebellType: .double, weight: 20, minutes: 20)
        #expect(c.workoutType == .abc)
    }

    @Test func emomFactoryTargetRoundsEqualsMinutes() {
        let c = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 15)
        #expect(c.targetRounds == 15)
    }

    @Test func emomFactoryRestDurationIsNil() {
        let c = WorkoutConfig.emom(kettlebellType: .double, weight: 20, minutes: 20)
        #expect(c.restDuration == nil)
    }

    @Test func emomFactoryTargetLaddersIsZero() {
        let c = WorkoutConfig.emom(kettlebellType: .double, weight: 20, minutes: 20)
        #expect(c.targetLadders == 0)
    }

    @Test func emomFactoryPreservesKettlebellType() {
        let c = WorkoutConfig.emom(kettlebellType: .single, weight: 24, minutes: 10)
        #expect(c.kettlebellType == .single)
        #expect(c.weight == 24)
    }

    // MARK: - rounds factory

    @Test func roundsFactoryModeIsRounds() {
        let c = WorkoutConfig.rounds(kettlebellType: .double, weight: 20, rounds: 5, restSeconds: 90)
        #expect(c.mode == .rounds)
    }

    @Test func roundsFactoryWorkoutTypeIsABC() {
        let c = WorkoutConfig.rounds(kettlebellType: .double, weight: 20, rounds: 5, restSeconds: 90)
        #expect(c.workoutType == .abc)
    }

    @Test func roundsFactoryTargetRoundsEqualsRounds() {
        let c = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 8, restSeconds: 60)
        #expect(c.targetRounds == 8)
    }

    @Test func roundsFactoryRestDurationEqualsRestSeconds() {
        let c = WorkoutConfig.rounds(kettlebellType: .double, weight: 20, rounds: 5, restSeconds: 90)
        #expect(c.restDuration == 90)
    }

    @Test func roundsFactoryTargetLaddersIsZero() {
        let c = WorkoutConfig.rounds(kettlebellType: .double, weight: 20, rounds: 5, restSeconds: 90)
        #expect(c.targetLadders == 0)
    }

    @Test func roundsFactoryPreservesKettlebellTypeAndWeight() {
        let c = WorkoutConfig.rounds(kettlebellType: .single, weight: 24, rounds: 3, restSeconds: 120)
        #expect(c.kettlebellType == .single)
        #expect(c.weight == 24)
    }

    // MARK: - press factory (non-duplicate scenarios only)

    @Test func pressFactoryModeIsEMOM() {
        let c = WorkoutConfig.press(kettlebellType: .single, weight: 16, targetLadders: 5)
        #expect(c.mode == .emom)
    }

    @Test func pressFactoryTargetRoundsIsZero() {
        let c = WorkoutConfig.press(kettlebellType: .single, weight: 16, targetLadders: 5)
        #expect(c.targetRounds == 0)
    }

    @Test func pressFactoryRestDurationIsNil() {
        let c = WorkoutConfig.press(kettlebellType: .single, weight: 16, targetLadders: 5)
        #expect(c.restDuration == nil)
    }

    @Test func pressFactoryDoubleKB() {
        let c = WorkoutConfig.press(kettlebellType: .double, weight: 20, targetLadders: 3)
        #expect(c.kettlebellType == .double)
        #expect(c.weight == 20)
        #expect(c.targetLadders == 3)
    }

    @Test func pressFactoryWorkoutTypeIsPress() {
        let c = WorkoutConfig.press(kettlebellType: .double, weight: 20, targetLadders: 3)
        #expect(c.workoutType == .press)
    }

    // MARK: - weightDisplay (WorkoutConfig)

    @Test func configWeightDisplaySingle() {
        let c = WorkoutConfig.emom(kettlebellType: .single, weight: 20, minutes: 20)
        #expect(c.weightDisplay == "20kg")
    }

    @Test func configWeightDisplayDouble() {
        let c = WorkoutConfig.emom(kettlebellType: .double, weight: 20, minutes: 20)
        #expect(c.weightDisplay == "2×20kg")
    }
}
