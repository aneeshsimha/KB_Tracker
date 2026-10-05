import Foundation
import Testing
@testable import KB_Tracker

@Suite(.serialized)
@MainActor
struct RuntimeTests {
    final class AudioSpy: AudioCueing {
        var countdowns = 0
        var starts = 0
        var completions = 0
        func playCountdownBeep() { countdowns += 1 }
        func playGoBeep() { starts += 1 }
        func playCompletionSound() { completions += 1 }
    }

    final class Clock {
        var date = Date(timeIntervalSince1970: 10_000)
        func advance(_ seconds: TimeInterval) { date = date.addingTimeInterval(seconds) }
    }

    private func definition(kind: BlockKind, rounds: Int = 3, work: Int = 10,
                            rest: Int = 0) -> WorkoutDefinition {
        WorkoutDefinition(name: "Test", blocks: [WorkoutBlock(name: "Block", kind: kind,
            movements: [.init(name: "Swing", reps: 10)], loadKg: 16, bells: 1,
            rounds: rounds, workSeconds: work, restSeconds: rest)])
    }

    @Test func emomBackgroundCatchupSkipsEmptySlotsWithoutInventingResults() {
        let clock = Clock()
        let runtime = WorkoutRuntime(definition: definition(kind: .emom, rounds: 4), now: { clock.date })
        runtime.start()
        clock.advance(TimeInterval(WorkoutParameters.getReadySeconds + 121))
        runtime.refresh()
        #expect(runtime.snapshot.setIndex == 2)
        #expect(runtime.snapshot.results.isEmpty)
        #expect(runtime.snapshot.phase == .working)
    }

    @Test func initialCountdownUsesAnAbsoluteDeadline() {
        let clock = Clock()
        let runtime = WorkoutRuntime(definition: definition(kind: .rounds), now: { clock.date })
        runtime.start()
        let deadline = clock.date.addingTimeInterval(TimeInterval(WorkoutParameters.getReadySeconds))
        #expect(runtime.snapshot.phase == .getReady)
        #expect(runtime.deadline == deadline)
        clock.advance(TimeInterval(WorkoutParameters.getReadySeconds) - 0.01)
        runtime.refresh()
        #expect(runtime.snapshot.phase == .getReady)
        clock.advance(0.01)
        runtime.refresh()
        #expect(runtime.snapshot.phase == .working)
        #expect(runtime.snapshot.phaseStartedAt == deadline)
    }

    @Test func countdownCuePlaysOncePerSecondAndMissedCuesAreNotReplayed() {
        let clock = Clock()
        let audio = AudioSpy()
        let runtime = WorkoutRuntime(definition: definition(kind: .rounds),
                                     now: { clock.date }, audio: audio)
        runtime.start()
        clock.advance(TimeInterval(WorkoutParameters.getReadySeconds - 3))
        runtime.refresh()
        runtime.refresh()
        #expect(audio.countdowns == 1)
        clock.advance(1)
        runtime.refresh()
        #expect(audio.countdowns == 2)

        let catchupClock = Clock()
        let catchupAudio = AudioSpy()
        let caughtUp = WorkoutRuntime(definition: definition(kind: .emom),
                                      now: { catchupClock.date }, audio: catchupAudio)
        caughtUp.start()
        catchupClock.advance(TimeInterval(WorkoutParameters.getReadySeconds + 61))
        caughtUp.refresh()
        #expect(catchupAudio.countdowns == 0)
    }

    @Test func startedEmomSetRemainsLateAfterDeadline() {
        let clock = Clock()
        let runtime = WorkoutRuntime(definition: definition(kind: .emom), now: { clock.date })
        runtime.start()
        clock.advance(TimeInterval(WorkoutParameters.getReadySeconds))
        runtime.refresh()
        runtime.beginSet()
        clock.advance(75)
        runtime.refresh()
        #expect(runtime.snapshot.setIndex == 0)
        #expect(runtime.isLate)
        #expect(runtime.snapshot.results.isEmpty)
    }

    @Test func pauseMovesDeadlineAndDoesNotAddElapsedTime() {
        let clock = Clock()
        let runtime = WorkoutRuntime(definition: definition(kind: .warmup), now: { clock.date })
        runtime.start()
        clock.advance(2)
        runtime.pause()
        let before = runtime.elapsed
        clock.advance(30)
        runtime.resume()
        #expect(runtime.elapsed == before)
        #expect(runtime.deadline == Date(timeIntervalSince1970: 10_000 + Double(WorkoutParameters.getReadySeconds) + 30))
    }

    @Test func pauseDuringRestPreservesTheRemainingRest() {
        let clock = Clock()
        let runtime = WorkoutRuntime(definition: definition(kind: .rounds, rounds: 2, rest: 10), now: { clock.date })
        runtime.start()
        clock.advance(TimeInterval(WorkoutParameters.getReadySeconds))
        runtime.refresh()
        runtime.logSet(repetitions: [.init(name: "Swing", reps: 10)])
        clock.advance(4)
        runtime.refresh()
        runtime.pause()
        clock.advance(40)
        runtime.resume()
        #expect(runtime.remaining == 6)
        clock.advance(6)
        runtime.refresh()
        #expect(runtime.snapshot.phase == .working)
    }

    @Test func pausedWaitingTimeIsFullyExcludedWhenNextBlockStarts() {
        let clock = Clock()
        let first = WorkoutBlock(name: "One", kind: .rounds, rounds: 1)
        let second = WorkoutBlock(name: "Two", kind: .rounds, rounds: 1)
        let runtime = WorkoutRuntime(definition: WorkoutDefinition(name: "Mixed", blocks: [first, second]), now: { clock.date })
        runtime.start()
        clock.advance(TimeInterval(WorkoutParameters.getReadySeconds))
        runtime.refresh()
        runtime.logSet()
        let workoutTime = runtime.elapsed
        clock.advance(10)
        runtime.pause()
        clock.advance(30)
        runtime.resume()
        clock.advance(20)
        runtime.startNextBlock()
        #expect(runtime.elapsed == workoutTime)
    }

    @Test func intervalAutoLogsUnknownRepsAndAdvancesAfterRest() {
        let clock = Clock()
        let runtime = WorkoutRuntime(definition: definition(kind: .interval, rounds: 2, work: 10, rest: 5), now: { clock.date })
        runtime.start()
        clock.advance(TimeInterval(WorkoutParameters.getReadySeconds + 10))
        runtime.refresh()
        #expect(runtime.snapshot.phase == .rest)
        #expect(runtime.snapshot.results.count == 1)
        #expect(runtime.snapshot.results[0].repetitions.isEmpty)
        clock.advance(5)
        runtime.refresh()
        #expect(runtime.snapshot.phase == .working)
        #expect(runtime.snapshot.setIndex == 1)
    }

    @Test func waitingBetweenBlocksIsExcludedFromSessionDuration() {
        let clock = Clock()
        let first = WorkoutBlock(name: "One", kind: .rounds, rounds: 1, workSeconds: 10, restSeconds: 0)
        let second = WorkoutBlock(name: "Two", kind: .rounds, rounds: 1, workSeconds: 10, restSeconds: 0)
        let runtime = WorkoutRuntime(definition: WorkoutDefinition(name: "Mixed", blocks: [first, second]), now: { clock.date })
        runtime.start()
        clock.advance(TimeInterval(WorkoutParameters.getReadySeconds))
        runtime.refresh()
        runtime.logSet(repetitions: [.init(name: "Swing", reps: 10)])
        let beforeWait = runtime.elapsed
        clock.advance(90)
        runtime.refresh()
        runtime.startNextBlock()
        #expect(runtime.elapsed == beforeWait)
    }

    @Test func completionFreezesDurationAndPlaysCompletionOnlyOnce() {
        let clock = Clock()
        let audio = AudioSpy()
        let runtime = WorkoutRuntime(definition: definition(kind: .warmup, rounds: 1, work: 10),
                                     now: { clock.date }, audio: audio)
        runtime.start()
        clock.advance(TimeInterval(WorkoutParameters.getReadySeconds + 10))
        runtime.refresh()
        let duration = runtime.elapsed
        #expect(runtime.isComplete)
        #expect(audio.completions == 1)
        clock.advance(500)
        runtime.refresh()
        #expect(runtime.elapsed == duration)
        #expect(audio.completions == 1)
    }

    @Test func undoAfterCompletionRestoresAFullDurableCheckpoint() throws {
        defer { try? ActiveWorkoutStore.clear() }
        let clock = Clock()
        let runtime = WorkoutRuntime(definition: definition(kind: .rounds, rounds: 1), now: { clock.date })
        runtime.start()
        clock.advance(TimeInterval(WorkoutParameters.getReadySeconds))
        runtime.refresh()
        runtime.logSet(repetitions: [.init(name: "Swing", reps: 7)])
        #expect(runtime.isComplete)
        runtime.undo()
        let restored = try #require(ActiveWorkoutStore.load())
        #expect(restored.phase == .working)
        #expect(restored.endedAt == nil)
        #expect(restored.results.isEmpty)
        #expect(restored.definition == runtime.snapshot.definition)
    }

    @Test func missedEmomSlotsNeverCountAsCompletedSets() {
        let clock = Clock()
        let audio = AudioSpy()
        let runtime = WorkoutRuntime(definition: definition(kind: .emom, rounds: 2),
                                     now: { clock.date }, audio: audio)
        runtime.start()
        clock.advance(TimeInterval(WorkoutParameters.getReadySeconds + 120))
        runtime.refresh()
        #expect(runtime.isComplete)
        #expect(runtime.completedSetCount == 0)
        #expect(runtime.makeSession().completedRounds == 0)
        #expect(audio.starts == 0)
        #expect(audio.completions == 1)
    }

    @Test func nonFiniteLoadIsRejectedByDefinitionValidation() {
        var invalid = definition(kind: .rounds)
        invalid.blocks[0].loadKg = .infinity
        #expect(invalid.validationError != nil)
    }

    @Test func CreatingSessionDoesNotClearCheckpointBeforeRepositorySave() {
        defer { try? ActiveWorkoutStore.clear() }
        let clock = Clock()
        let runtime = WorkoutRuntime(definition: definition(kind: .rounds, rounds: 1), now: { clock.date })
        runtime.start()
        _ = runtime.makeSession()
        #expect(ActiveWorkoutStore.load()?.id == runtime.snapshot.id)
    }
}
