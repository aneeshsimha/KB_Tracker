import Testing
import Foundation
@testable import KB_Tracker

struct MetricsTests {
    @Test func completionRateUsesRecordedSets() {
        let session = WorkoutSession()
        session.results = [
            WorkoutSetResult(blockID: UUID(), setIndex: 0, loadKg: 16, bells: 1, completed: true),
            WorkoutSetResult(blockID: UUID(), setIndex: 1, loadKg: 16, bells: 1, completed: false)
        ]
        #expect(SessionMetrics.completionRate(session) == 0.5)
    }

    @Test func testPaceDoesNotCompareDifferentPrescriptions() {
        let leftDefinition = WorkoutDefinition(name: "A", blocks: [WorkoutBlock()])
        var rightBlock = WorkoutBlock(); rightBlock.rounds = 9
        let rightDefinition = WorkoutDefinition(name: "A", blocks: [rightBlock])
        let left = WorkoutSession(); left.definition = leftDefinition; left.isCompleted = true; left.totalDuration = 300
        let right = WorkoutSession(); right.definition = rightDefinition; right.isCompleted = true; right.totalDuration = 250
        #expect(!SessionMetrics.isComparablePace(left, right))
    }

    @Test func incompleteMovementEntryDoesNotBecomeRecordedTotal() {
        let block = WorkoutBlock(movements: [.init(name: "Clean", reps: 2), .init(name: "Press", reps: 1)])
        let session = WorkoutSession()
        session.definition = WorkoutDefinition(name: "ABC", blocks: [block])
        session.results = [WorkoutSetResult(blockID: block.id, setIndex: 0, repetitions: [.init(name: "Clean", reps: 2)], loadKg: 16, bells: 2)]
        #expect(session.recordedReps == nil)
        #expect(session.recordedVolume == nil)
    }

    @Test func movementVolumeUsesTheLoadRecordedOnEachSet() {
        let session = WorkoutSession()
        session.results = [
            WorkoutSetResult(blockID: UUID(), setIndex: 0, repetitions: [.init(name: "Swing", reps: 10)], loadKg: 16, bells: 1),
            WorkoutSetResult(blockID: UUID(), setIndex: 1, repetitions: [.init(name: "Swing", reps: 10)], loadKg: 20, bells: 1)
        ]
        #expect(SessionMetrics.movementVolume([session])["Swing"] == 360)
    }
}
