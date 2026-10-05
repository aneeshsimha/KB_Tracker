import Foundation
import Combine

@MainActor
final class WorkoutRuntime: ObservableObject {
    @Published private(set) var snapshot: ActiveWorkoutSnapshot
    @Published private(set) var displayNow: Date
    @Published private(set) var persistenceError: String? = nil

    private let now: () -> Date
    private let audio: AudioCueing
    private var lastCountdownCue: (deadline: Date, second: Int)?

    init(definition: WorkoutDefinition, programID: UUID? = nil,
         now: @escaping () -> Date = Date.init, audio: AudioCueing? = nil) {
        self.snapshot = ActiveWorkoutSnapshot(definition: definition, programID: programID,
                                              getReadySeconds: WorkoutParameters.getReadySeconds)
        self.now = now
        self.audio = audio ?? AudioService.shared
        self.displayNow = now()
    }

    init(snapshot: ActiveWorkoutSnapshot, now: @escaping () -> Date = Date.init,
         audio: AudioCueing? = nil) {
        var restored = snapshot
        restored.getReadySeconds = snapshot.getReadySeconds ?? WorkoutParameters.getReadySeconds
        self.snapshot = restored
        self.now = now
        self.audio = audio ?? AudioService.shared
        self.displayNow = now()
        refresh()
    }

    var block: WorkoutBlock? {
        snapshot.definition.blocks.indices.contains(snapshot.blockIndex)
            ? snapshot.definition.blocks[snapshot.blockIndex] : nil
    }

    var isPaused: Bool { snapshot.pausedAt != nil }
    var isComplete: Bool { snapshot.phase == .complete }
    var completedSetCount: Int { snapshot.results.filter(\.completed).count }
    var currentSetNumber: Int { snapshot.setIndex + 1 }
    var isCurrentSetLogged: Bool {
        guard let block else { return false }
        return snapshot.results.contains { $0.blockID == block.id && $0.setIndex == snapshot.setIndex }
    }
    var canUndoCurrentBlock: Bool {
        guard let result = snapshot.results.last,
              snapshot.definition.blocks.indices.contains(snapshot.blockIndex) else { return false }
        return result.blockID == snapshot.definition.blocks[snapshot.blockIndex].id
    }
    private var getReadySeconds: Int { snapshot.getReadySeconds ?? WorkoutParameters.getReadySeconds }
    var elapsed: TimeInterval {
        guard let startedAt = snapshot.startedAt else { return 0 }
        if snapshot.phase == .getReady { return 0 }
        let end = snapshot.endedAt ?? snapshot.pausedAt ?? displayNow
        return max(0, end.timeIntervalSince(startedAt) - snapshot.pausedDuration)
    }
    var phaseElapsed: TimeInterval {
        guard let date = snapshot.phaseStartedAt else { return 0 }
        return max(0, (snapshot.pausedAt ?? displayNow).timeIntervalSince(date))
    }
    var deadline: Date? {
        guard let block, let anchor = snapshot.phaseStartedAt, !isPaused else { return nil }
        switch snapshot.phase {
        case .getReady: return anchor.addingTimeInterval(Double(getReadySeconds))
        case .working where block.kind == .emom: return anchor.addingTimeInterval(60)
        case .working where block.kind.isTimed: return anchor.addingTimeInterval(Double(block.workSeconds))
        case .rest: return anchor.addingTimeInterval(Double(block.restSeconds))
        default: return nil
        }
    }
    var remaining: TimeInterval? {
        guard let block else { return nil }
        switch snapshot.phase {
        case .getReady: return max(0, Double(getReadySeconds) - phaseElapsed)
        case .working where block.kind == .emom: return max(0, 60 - phaseElapsed)
        case .working where block.kind.isTimed: return max(0, Double(block.workSeconds) - phaseElapsed)
        case .rest: return max(0, Double(block.restSeconds) - phaseElapsed)
        default: return nil
        }
    }
    var isLate: Bool {
        guard let block, snapshot.phase == .working else { return false }
        return block.kind == .emom && snapshot.activeSetStartedAt != nil && phaseElapsed >= 60
    }

    /// Idempotent across duplicate view appearances and restored checkpoints.
    func start() {
        guard snapshot.startedAt == nil, !snapshot.definition.blocks.isEmpty else { return }
        let date = now()
        snapshot.startedAt = date
        snapshot.phaseStartedAt = date
        snapshot.phase = .getReady
        displayNow = date
        persist()
        LiveActivityService.shared.start(workoutType: snapshot.definition.name,
                                         totalTarget: totalSets, mode: "workout",
                                         getReadySeconds: getReadySeconds)
    }

    func refresh() {
        let date = now()
        displayNow = date
        guard snapshot.startedAt != nil, snapshot.pausedAt == nil,
              snapshot.phase != .complete else { return }
        playCountdownCueIfNeeded(at: date)
        // Each transition consumes its own absolute deadline. The loop catches up after
        // app suspension without replaying cues for past slots.
        var transitions = 0
        while transitions < 10_000 {
            transitions += 1
            guard let block, let anchor = snapshot.phaseStartedAt else { break }
            switch snapshot.phase {
            case .getReady:
                let deadline = anchor.addingTimeInterval(Double(getReadySeconds))
                guard date >= deadline else { return }
                snapshot.phase = .working
                snapshot.phaseStartedAt = deadline
                snapshot.pausedDuration += Double(getReadySeconds)
                persist()
                if date.timeIntervalSince(deadline) < 1 {
                    audio.playGoBeep()
                    audio.announce(block.name)
                }
            case .working where block.kind == .emom:
                let deadline = anchor.addingTimeInterval(60)
                guard date >= deadline, snapshot.activeSetStartedAt == nil else { return }
                advanceSet(at: deadline, resting: false)
            case .working where block.kind.isTimed:
                let deadline = anchor.addingTimeInterval(Double(block.workSeconds))
                guard date >= deadline else { return }
                appendAutomaticResult(for: block, at: deadline)
                if block.kind == .interval && block.restSeconds > 0 && snapshot.setIndex + 1 < block.targetSets {
                    snapshot.phase = .rest
                    snapshot.phaseStartedAt = deadline
                    persist()
                } else {
                    advanceSet(at: deadline, resting: false)
                }
            case .rest:
                let deadline = anchor.addingTimeInterval(Double(block.restSeconds))
                guard date >= deadline else { return }
                snapshot.phase = .working
                snapshot.phaseStartedAt = deadline
                snapshot.activeSetStartedAt = nil
                if block.kind == .interval { snapshot.setIndex += 1 }
                persist()
                if date.timeIntervalSince(deadline) < 1 { audio.announce("Work") }
            default: return
            }
        }
    }

    /// Marks an EMOM set as underway. Its minute may then run late until it is logged.
    func beginSet() {
        refresh()
        guard snapshot.phase == .working, !isPaused, block?.kind == .emom,
              snapshot.activeSetStartedAt == nil,
              !snapshot.results.contains(where: { $0.blockID == block?.id && $0.setIndex == snapshot.setIndex })
        else { return }
        snapshot.activeSetStartedAt = now()
        persist()
    }

    func pause() {
        refresh()
        guard snapshot.startedAt != nil, snapshot.phase != .complete,
              snapshot.pausedAt == nil else { return }
        snapshot.pausedAt = now()
        persist()
    }

    func resume() {
        guard let pausedAt = snapshot.pausedAt else { return }
        let date = now()
        let paused = max(0, date.timeIntervalSince(pausedAt))
        snapshot.pausedDuration += paused
        snapshot.phaseStartedAt = snapshot.phaseStartedAt?.addingTimeInterval(paused)
        snapshot.activeSetStartedAt = snapshot.activeSetStartedAt?.addingTimeInterval(paused)
        snapshot.pausedAt = nil
        displayNow = date
        persist()
    }

    /// Repetitions are actual totals, never inferred from the prescription.
    func logSet(repetitions: [MovementReps] = []) {
        refresh()
        guard let block, snapshot.phase == .working, !isPaused,
              !snapshot.results.contains(where: { $0.blockID == block.id && $0.setIndex == snapshot.setIndex })
        else { return }
        let date = now()
        let duration = snapshot.activeSetStartedAt.map { max(0, date.timeIntervalSince($0)) }
            ?? snapshot.phaseStartedAt.map { max(0, date.timeIntervalSince($0)) }
        let result = WorkoutSetResult(blockID: block.id, setIndex: snapshot.setIndex,
                                      duration: duration, repetitions: repetitions,
                                      loadKg: block.loadKg, bells: block.bells)
        snapshot.results.append(result)
        snapshot.lastLoggedAt = date
        snapshot.activeSetStartedAt = nil
        if block.kind == .emom {
            // Preserve the minute boundary. A late set advances immediately.
            if phaseElapsed >= 60 { advanceSet(at: date, resting: false) }
            else { persist() }
        } else if block.kind == .interval {
            persist() // The work/rest clock controls interval transitions.
        } else {
            advanceSet(at: date, resting: block.kind == .rounds)
        }
    }

    func undo() {
        guard !isPaused, let result = snapshot.results.last,
              let block = snapshot.definition.blocks.first(where: { $0.id == result.blockID }),
              snapshot.blockIndex == snapshot.definition.blocks.firstIndex(where: { $0.id == result.blockID })
        else { return }
        let date = now()
        if snapshot.phase == .complete, let endedAt = snapshot.endedAt {
            snapshot.pausedDuration += max(0, date.timeIntervalSince(endedAt))
        }
        displayNow = date
        if snapshot.phase == .waitingNext, let waitingSince = snapshot.phaseStartedAt {
            snapshot.pausedDuration += max(0, (snapshot.pausedAt ?? date).timeIntervalSince(waitingSince))
        }
        snapshot.endedAt = nil
        snapshot.isPartial = false
        snapshot.results.removeLast()
        snapshot.setIndex = result.setIndex
        snapshot.phase = .working
        snapshot.phaseStartedAt = date
        snapshot.activeSetStartedAt = block.kind == .emom ? snapshot.phaseStartedAt : nil
        snapshot.lastLoggedAt = nil
        persist()
    }

    func startNextBlock() {
        guard snapshot.phase == .waitingNext, !isPaused,
              snapshot.blockIndex + 1 < snapshot.definition.blocks.count else { return }
        let date = now()
        if let waitingSince = snapshot.phaseStartedAt {
            snapshot.pausedDuration += max(0, date.timeIntervalSince(waitingSince))
        }
        snapshot.blockIndex += 1
        snapshot.setIndex = 0
        snapshot.phase = .working
        snapshot.phaseStartedAt = date
        snapshot.activeSetStartedAt = nil
        persist()
        audio.playGoBeep()
        audio.announce(snapshot.definition.blocks[snapshot.blockIndex].name)
    }

    func finishEarly() {
        guard snapshot.startedAt != nil, snapshot.phase != .complete else { return }
        let date = now()
        let pauseStartedAt = snapshot.pausedAt
        if snapshot.phase == .waitingNext, let waitingSince = snapshot.phaseStartedAt {
            snapshot.pausedDuration += max(0, (pauseStartedAt ?? date).timeIntervalSince(waitingSince))
        }
        if let pausedAt = snapshot.pausedAt {
            snapshot.pausedDuration += max(0, date.timeIntervalSince(pausedAt))
            snapshot.pausedAt = nil
        }
        snapshot.isPartial = true
        complete(at: date)
    }

    @discardableResult
    func discard() -> Bool {
        do { try ActiveWorkoutStore.clear() }
        catch { persistenceError = error.localizedDescription; return false }
        NotificationService.cancelWorkoutCue()
        LiveActivityService.shared.end(currentRound: completedSetCount,
                                       totalRounds: totalSets, elapsedSeconds: elapsed, mode: "workout")
        persistenceError = nil
        return true
    }

    func makeSession() -> WorkoutSession {
        guard let first = snapshot.definition.blocks.first else {
            let session = WorkoutSession()
            session.id = snapshot.id
            session.date = snapshot.startedAt ?? now()
            session.endedAt = snapshot.endedAt ?? now()
            session.totalDuration = elapsed
            session.isCompleted = false
            session.notes = snapshot.notes.isEmpty ? nil : snapshot.notes
            return session
        }
        let session = WorkoutSession(mode: first.kind == .emom ? .emom : .rounds,
                                     kettlebellType: first.bells == 2 ? .double : .single,
                                     weight: Int(first.loadKg.rounded()),
                                     targetRounds: first.kind == .ladder ? first.rounds : first.targetSets,
                                     restDuration: first.restSeconds)
        session.id = snapshot.id
        session.date = snapshot.startedAt ?? now()
        session.endedAt = snapshot.endedAt ?? now()
        session.totalDuration = elapsed
        session.pausedDuration = snapshot.pausedDuration
        session.workoutType = snapshot.definition.workoutType
        session.definition = snapshot.definition
        session.results = snapshot.results
        session.completedRounds = completedSetCount
        session.setTimes = snapshot.results.compactMap(\.duration)
        session.notes = snapshot.notes.isEmpty ? nil : snapshot.notes
        session.difficulty = snapshot.difficulty
        session.programID = snapshot.programID
        session.sourceRaw = "runner"
        session.isCompleted = !snapshot.isPartial && snapshot.phase == .complete
        if first.kind == .ladder {
            let count = max(1, first.rungs.count)
            session.targetLadders = first.rounds
            session.ladderReps = stride(from: 0, to: first.targetSets, by: count).map { start in
                snapshot.results.filter { $0.blockID == first.id && $0.setIndex >= start && $0.setIndex < start + count }
                    .reduce(0) { $0 + ($1.totalReps ?? 0) }
            }.filter { $0 > 0 }
        }
        return session
    }

    func setSummary(notes: String, difficulty: SessionDifficulty?) {
        snapshot.notes = notes
        snapshot.difficulty = difficulty
        persist()
    }

    func retryPersistence() { persist() }
    func acknowledgePersistenceError() { persistenceError = nil }

    private var totalSets: Int { snapshot.definition.blocks.reduce(0) { $0 + $1.targetSets } }

    private func advanceSet(at date: Date, resting: Bool) {
        guard let block else { return }
        snapshot.activeSetStartedAt = nil
        if snapshot.setIndex + 1 >= block.targetSets {
            if snapshot.blockIndex + 1 < snapshot.definition.blocks.count {
                snapshot.phase = .waitingNext
                snapshot.phaseStartedAt = date
                persist()
                if date.timeIntervalSince(now()) > -1 { audio.announce("Block complete") }
            } else { complete(at: date) }
        } else {
            snapshot.setIndex += 1
            snapshot.phase = resting && block.restSeconds > 0 ? .rest : .working
            snapshot.phaseStartedAt = date
            persist()
            if date.timeIntervalSince(now()) > -1 {
                if snapshot.phase == .working {
                    audio.playGoBeep()
                    if block.kind == .ladder {
                        audio.announce("Ladder \(snapshot.setIndex / block.rungs.count + 1), \(block.rungs[snapshot.setIndex % block.rungs.count]) reps")
                    } else { audio.announce("Round \(snapshot.setIndex + 1)") }
                }
                else if snapshot.phase == .rest { audio.announce("Rest") }
            }
        }
    }

    private func appendAutomaticResult(for block: WorkoutBlock, at date: Date) {
        guard !snapshot.results.contains(where: { $0.blockID == block.id && $0.setIndex == snapshot.setIndex }) else { return }
        snapshot.results.append(WorkoutSetResult(blockID: block.id,
                                                 setIndex: snapshot.setIndex,
                                                 duration: Double(block.workSeconds),
                                                 repetitions: [],
                                                 loadKg: block.loadKg,
                                                 bells: block.bells))
        snapshot.lastLoggedAt = date
    }

    private func playCountdownCueIfNeeded(at date: Date) {
        guard let deadline else { return }
        let seconds = Int(ceil(deadline.timeIntervalSince(date)))
        guard (1...3).contains(seconds) else { return }
        guard lastCountdownCue?.deadline != deadline || lastCountdownCue?.second != seconds else { return }
        lastCountdownCue = (deadline, seconds)
        audio.playCountdownBeep()
    }

    private func complete(at date: Date) {
        if completedSetCount < totalSets { snapshot.isPartial = true }
        snapshot.phase = .complete
        snapshot.endedAt = date
        snapshot.phaseStartedAt = date
        persist()
        NotificationService.cancelWorkoutCue()
        audio.playCompletionSound()
        LiveActivityService.shared.end(currentRound: completedSetCount,
                                       totalRounds: totalSets, elapsedSeconds: elapsed, mode: "workout")
    }

    private func persist() {
        do {
            try ActiveWorkoutStore.save(snapshot)
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
        }
        guard snapshot.startedAt != nil, snapshot.phase != .complete else { return }
        LiveActivityService.shared.update(phase: isPaused ? "paused" : snapshot.phase.rawValue,
                                          currentRound: completedSetCount,
                                          totalRounds: totalSets,
                                          elapsedSeconds: elapsed, mode: "workout",
                                          countdownEndDate: deadline ?? snapshot.phaseStartedAt ?? now())
        if let deadline {
            Task { await NotificationService.scheduleWorkoutCue(at: deadline, title: snapshot.definition.name) }
        } else {
            NotificationService.cancelWorkoutCue()
        }
    }
}
