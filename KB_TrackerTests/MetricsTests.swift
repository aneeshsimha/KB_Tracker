import Testing
import Foundation
@testable import KB_Tracker

struct MetricsTests {
    private func paceSession(definition: WorkoutDefinition, reps: Int = 10,
                             load: Double? = nil) -> WorkoutSession {
        let session = WorkoutSession()
        session.definition = definition
        session.isCompleted = true
        session.totalDuration = 300
        session.results = definition.blocks.flatMap { block in
            (0..<block.targetSets).map { index in
                let movements: [MovementReps]
                if block.kind == .ladder {
                    movements = [.init(name: block.movements[0].name,
                                       reps: block.rungs[index % block.rungs.count])]
                } else {
                    movements = block.movements.compactMap { movement in
                        movement.reps.map { _ in .init(name: movement.name, reps: reps) }
                    }
                }
                return WorkoutSetResult(blockID: block.id, setIndex: index, duration: 10,
                                        repetitions: movements, loadKg: load ?? block.loadKg,
                                        bells: block.bells)
            }
        }
        return session
    }

    @Test func completionRateUsesRecordedSets() {
        let session = WorkoutSession()
        session.results = [
            WorkoutSetResult(blockID: UUID(), setIndex: 0, loadKg: 16, bells: 1, completed: true),
            WorkoutSetResult(blockID: UUID(), setIndex: 1, loadKg: 16, bells: 1, completed: false)
        ]
        #expect(SessionMetrics.completionRate(session) == 0.5)
    }

    @Test func completionRateUsesPrescriptionTargetNotLoggedResultCount() {
        var block = WorkoutBlock(); block.rounds = 10
        let session = WorkoutSession(); session.definition = WorkoutDefinition(name: "Ten", blocks: [block])
        session.results = (0..<3).map { WorkoutSetResult(blockID: block.id, setIndex: $0, loadKg: 16, bells: 1, completed: true) }
        #expect(SessionMetrics.completionRate(session) == 0.3)
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

    @Test func automaticSessionWithoutActualResultsIsNotPaceEligible() {
        let definition = WorkoutDefinition(name: "Rounds", blocks: [WorkoutBlock(rounds: 2)])
        let session = WorkoutSession()
        session.definition = definition
        session.isCompleted = true
        session.totalDuration = 20
        session.sourceRaw = "runner"
        #expect(!SessionMetrics.paceEligible(session))
    }

    @Test func fewerRepsCannotBecomeAFasterComparablePace() {
        let block = WorkoutBlock(movements: [.init(name: "Swing", reps: 10)], rounds: 1)
        let definition = WorkoutDefinition(name: "Swing", blocks: [block])
        let complete = paceSession(definition: definition, reps: 10)
        let underTarget = paceSession(definition: definition, reps: 9)
        underTarget.totalDuration = 5
        #expect(SessionMetrics.paceEligible(complete))
        #expect(!SessionMetrics.paceEligible(underTarget))
        #expect(!SessionMetrics.isComparablePace(complete, underTarget))
    }

    @Test func mismatchedEquipmentAndDuplicateSlotsAreRejected() {
        let definition = WorkoutDefinition(name: "Swing", blocks: [WorkoutBlock(rounds: 2)])
        let wrongLoad = paceSession(definition: definition, load: 20)
        #expect(!SessionMetrics.paceEligible(wrongLoad))
        let duplicate = paceSession(definition: definition)
        duplicate.results[1].setIndex = 0
        #expect(!SessionMetrics.paceEligible(duplicate))
    }

    @Test func timedBlockWithoutPrescribedRepsCanBePaceEligible() {
        let block = WorkoutBlock(name: "Mobility", kind: .warmup,
                                 movements: [.init(name: "Flow")], rounds: 1,
                                 workSeconds: 60)
        let definition = WorkoutDefinition(name: "Warmup", blocks: [block])
        let session = paceSession(definition: definition)
        #expect(session.results[0].repetitions.isEmpty)
        #expect(SessionMetrics.paceEligible(session))
    }
}
