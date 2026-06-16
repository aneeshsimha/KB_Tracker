import Testing
import Foundation
@testable import KB_Tracker

struct WorkoutSessionTests {

    // MARK: - weightDisplay

    @Test func weightDisplaySingleKB() {
        let s = WorkoutSession()
        s.kettlebellType = .single
        s.weight = 20
        #expect(s.weightDisplay == "20kg")
    }

    @Test func weightDisplayDoubleKB() {
        let s = WorkoutSession()
        s.kettlebellType = .double
        s.weight = 20
        #expect(s.weightDisplay == "2×20kg")
    }

    @Test func weightDisplaySingleKBDifferentWeight() {
        let s = WorkoutSession()
        s.kettlebellType = .single
        s.weight = 16
        #expect(s.weightDisplay == "16kg")
    }

    @Test func weightDisplayDoubleKBDifferentWeight() {
        let s = WorkoutSession()
        s.kettlebellType = .double
        s.weight = 24
        #expect(s.weightDisplay == "2×24kg")
    }

    // MARK: - averageSetTime

    @Test func averageSetTimeNilWhenEmpty() {
        let s = WorkoutSession()
        s.setTimes = []
        #expect(s.averageSetTime == nil)
    }

    @Test func averageSetTimeSingleEntry() {
        let s = WorkoutSession()
        s.setTimes = [45.0]
        #expect(s.averageSetTime == 45.0)
    }

    @Test func averageSetTimeMultipleEntries() {
        let s = WorkoutSession()
        s.setTimes = [30.0, 40.0, 50.0]
        #expect(s.averageSetTime == 40.0)
    }

    @Test func averageSetTimeNonUniformValues() {
        let s = WorkoutSession()
        s.setTimes = [10.0, 90.0]
        #expect(s.averageSetTime == 50.0)
    }

    // MARK: - hasOvertimeSets

    @Test func hasOvertimeSetsReturnsFalseForRoundsModeEvenWithLongSets() {
        let s = WorkoutSession()
        s.mode = .rounds
        s.setTimes = [61.0, 90.0]
        #expect(s.hasOvertimeSets == false)
    }

    @Test func hasOvertimeSetsReturnsFalseForEMOMWithAllSetsUnder60() {
        let s = WorkoutSession()
        s.mode = .emom
        s.setTimes = [30.0, 55.0, 59.9]
        #expect(s.hasOvertimeSets == false)
    }

    @Test func hasOvertimeSetsReturnsTrueForEMOMWithOneLongSet() {
        let s = WorkoutSession()
        s.mode = .emom
        s.setTimes = [30.0, 61.0]
        #expect(s.hasOvertimeSets == true)
    }

    @Test func hasOvertimeSetsExactly60SecondsIsNotOvertime() {
        let s = WorkoutSession()
        s.mode = .emom
        s.setTimes = [60.0]
        #expect(s.hasOvertimeSets == false)
    }

    @Test func hasOvertimeSetsEmptySetTimesIsNotOvertime() {
        let s = WorkoutSession()
        s.mode = .emom
        s.setTimes = []
        #expect(s.hasOvertimeSets == false)
    }

    // MARK: - roundsDisplay

    @Test func roundsDisplayFormatsCompletedOverTarget() {
        let s = WorkoutSession()
        s.completedRounds = 18
        s.targetRounds = 20
        #expect(s.roundsDisplay == "18/20")
    }

    @Test func roundsDisplayZeroCompleted() {
        let s = WorkoutSession()
        s.completedRounds = 0
        s.targetRounds = 20
        #expect(s.roundsDisplay == "0/20")
    }

    @Test func roundsDisplayFullyCompleted() {
        let s = WorkoutSession()
        s.completedRounds = 10
        s.targetRounds = 10
        #expect(s.roundsDisplay == "10/10")
    }

    // MARK: - totalReps (non-duplicate scenarios only)

    @Test func totalRepsEmptyLadderReps() {
        let s = WorkoutSession()
        s.ladderReps = []
        #expect(s.totalReps == 0)
    }

    @Test func totalRepsSingleEntry() {
        let s = WorkoutSession()
        s.ladderReps = [20]
        #expect(s.totalReps == 20)
    }

    // MARK: - completedLadders (non-duplicate scenarios only)

    @Test func completedLaddersNoneWhenEmpty() {
        let s = WorkoutSession()
        s.ladderReps = []
        #expect(s.completedLadders == 0)
    }

    @Test func completedLaddersNoneWhenAllPartial() {
        let s = WorkoutSession()
        s.ladderReps = [10, 15, 19]
        #expect(s.completedLadders == 0)
    }

    @Test func completedLaddersAllFull() {
        let s = WorkoutSession()
        s.ladderReps = [20, 20, 20]
        #expect(s.completedLadders == 3)
    }
}
