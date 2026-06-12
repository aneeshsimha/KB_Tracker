import Testing
import Foundation
@testable import KB_Tracker

struct WorkoutParametersTests {
    @Test func weightBounds() {
        #expect(WorkoutParameters.weightMin == 12)
        #expect(WorkoutParameters.weightMax == 24)
        #expect(WorkoutParameters.weightStep == 2)
    }
    @Test func emomMinutesBounds() {
        #expect(WorkoutParameters.emomMinutesMin == 10)
        #expect(WorkoutParameters.emomMinutesMax == 30)
    }
    @Test func roundsBounds() {
        #expect(WorkoutParameters.roundsMin == 5)
        #expect(WorkoutParameters.roundsMax == 20)
    }
    @Test func restBounds() {
        #expect(WorkoutParameters.restMin == 30)
        #expect(WorkoutParameters.restMax == 120)
        #expect(WorkoutParameters.restStep == 15)
    }
    @Test func laddersBounds() {
        #expect(WorkoutParameters.laddersMin == 1)
        #expect(WorkoutParameters.laddersMax == 10)
    }
    @Test func getReadySeconds() {
        #expect(WorkoutParameters.getReadySeconds == 5)
    }
}
