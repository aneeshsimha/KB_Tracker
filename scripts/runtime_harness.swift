import Foundation

@main
struct RuntimeHarness {
    final class Clock {
        var date = Date(timeIntervalSince1970: 1_000_000)
        func advance(_ seconds: TimeInterval) { date.addTimeInterval(seconds) }
    }

    final class AudioSpy: AudioCueing {
        var countdown = 0
        var go = 0
        var complete = 0
        func playCountdownBeep() { countdown += 1 }
        func playGoBeep() { go += 1 }
        func playCompletionSound() { complete += 1 }
        func announce(_ phrase: String) {}
    }

    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError("FAIL: \(message)") }
    }

    static func block(_ kind: BlockKind, rounds: Int = 3, work: Int = 10,
                      rest: Int = 0, name: String = "Block") -> WorkoutBlock {
        WorkoutBlock(name: name, kind: kind,
                     movements: [.init(name: "Swing", reps: 10)],
                     loadKg: 16, bells: 1, rounds: rounds,
                     workSeconds: work, restSeconds: rest)
    }

    @MainActor
    static func main() throws {
        UserDefaults.standard.set(5, forKey: "kb_pref_getReady")
        try ActiveWorkoutStore.clear()
        defer { try? ActiveWorkoutStore.clear() }

        do {
            let clock = Clock()
            let audio = AudioSpy()
            let runtime = WorkoutRuntime(definition: .init(name: "EMOM", blocks: [block(.emom, rounds: 4)]),
                                         now: { clock.date }, audio: audio)
            runtime.start()
            expect(runtime.elapsed == 0, "get-ready countdown excluded from elapsed")
            expect(runtime.deadline == clock.date.addingTimeInterval(5), "get-ready deadline")
            UserDefaults.standard.set(10, forKey: "kb_pref_getReady")
            expect(runtime.deadline == clock.date.addingTimeInterval(5), "get-ready setting frozen per workout")
            UserDefaults.standard.set(5, forKey: "kb_pref_getReady")
            clock.advance(126)
            runtime.refresh()
            expect(runtime.snapshot.setIndex == 2, "EMOM catch-up index")
            expect(runtime.snapshot.results.isEmpty, "missed EMOM slots must not create results")
            expect(audio.countdown == 0 && audio.go == 0, "missed cues must not replay")
        }

        do {
            let clock = Clock()
            let runtime = WorkoutRuntime(definition: .init(name: "Late", blocks: [block(.emom)]),
                                         now: { clock.date })
            runtime.start()
            clock.advance(5)
            runtime.refresh()
            runtime.beginSet()
            clock.advance(75)
            runtime.refresh()
            expect(runtime.isLate && runtime.snapshot.setIndex == 0, "active EMOM set stays late")
        }

        do {
            let clock = Clock()
            let runtime = WorkoutRuntime(definition: .init(name: "Guard", blocks: [block(.emom)]),
                                         now: { clock.date })
            runtime.start()
            clock.advance(5)
            runtime.refresh()
            runtime.logSet(repetitions: [.init(name: "Swing", reps: 10)])
            runtime.beginSet()
            expect(runtime.snapshot.activeSetStartedAt == nil,
                   "logged EMOM slot cannot be started again")
        }

        do {
            let clock = Clock()
            let runtime = WorkoutRuntime(definition: .init(name: "Ladder", blocks: [block(.ladder, rounds: 2, rest: 60)]),
                                         now: { clock.date })
            runtime.start()
            clock.advance(5)
            runtime.refresh()
            runtime.logSet(repetitions: [.init(name: "Press", reps: 2)])
            expect(runtime.snapshot.phase == .working && runtime.snapshot.setIndex == 1,
                   "ladder advances without forced rest")
        }

        do {
            let clock = Clock()
            let runtime = WorkoutRuntime(definition: .init(name: "Intervals", blocks: [block(.interval, rounds: 2, work: 10, rest: 5)]),
                                         now: { clock.date })
            runtime.start()
            clock.advance(15)
            runtime.refresh()
            expect(runtime.snapshot.phase == .rest, "interval enters rest")
            expect(runtime.snapshot.results.count == 1 && runtime.snapshot.results[0].repetitions.isEmpty,
                   "timed result has unknown reps")
            runtime.pause()
            let elapsed = runtime.elapsed
            clock.advance(100)
            runtime.resume()
            expect(runtime.elapsed == elapsed, "pause excluded from elapsed")
            clock.advance(5)
            runtime.refresh()
            expect(runtime.snapshot.phase == .working && runtime.snapshot.setIndex == 1,
                   "interval resumes next work set")
        }

        do {
            let clock = Clock()
            let definition = WorkoutDefinition(name: "Mixed", blocks: [
                block(.rounds, rounds: 1, name: "One"),
                block(.rounds, rounds: 1, name: "Two")
            ])
            let runtime = WorkoutRuntime(definition: definition, now: { clock.date })
            runtime.start()
            clock.advance(5)
            runtime.refresh()
            runtime.logSet(repetitions: [.init(name: "Swing", reps: 8)])
            let elapsed = runtime.elapsed
            clock.advance(60)
            runtime.startNextBlock()
            expect(runtime.elapsed == elapsed, "between-block setup excluded")
            let restored = ActiveWorkoutStore.load()
            expect(restored?.definition == definition && restored?.results.count == 1,
                   "checkpoint contains definition and results")
        }

        do {
            let clock = Clock()
            let definition = WorkoutDefinition(name: "Partial", blocks: [
                block(.rounds, rounds: 1), block(.rounds, rounds: 1)
            ])
            let runtime = WorkoutRuntime(definition: definition, now: { clock.date })
            runtime.start()
            clock.advance(5)
            runtime.refresh()
            runtime.logSet()
            clock.advance(10)
            runtime.pause()
            clock.advance(30)
            runtime.finishEarly()
            expect(runtime.elapsed == 0, "paused waiting time excluded on early finish")
            expect(runtime.snapshot.pausedAt == nil && runtime.snapshot.isPartial,
                   "early finish normalizes pause and stays partial")
        }

        do {
            let clock = Clock()
            let audio = AudioSpy()
            let runtime = WorkoutRuntime(definition: .init(name: "Warmup", blocks: [block(.warmup, rounds: 1)]),
                                         now: { clock.date }, audio: audio)
            runtime.start()
            clock.advance(15)
            runtime.refresh()
            let duration = runtime.elapsed
            clock.advance(500)
            runtime.refresh()
            expect(runtime.elapsed == duration, "completed duration frozen")
            expect(audio.complete == 1, "completion cue exactly once")
            runtime.undo()
            let restored = ActiveWorkoutStore.load()
            expect(restored?.phase == .working && restored?.endedAt == nil && restored?.results.isEmpty == true,
                   "undo persists complete restored state")
        }

        var invalid = WorkoutDefinition(name: "Invalid", blocks: [block(.rounds)])
        invalid.blocks[0].loadKg = .nan
        expect(invalid.validationError != nil, "non-finite loads rejected")

        print("runtime_harness: 9 scenarios passed")
    }
}
