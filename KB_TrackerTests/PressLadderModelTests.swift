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
