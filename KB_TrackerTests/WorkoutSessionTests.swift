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
