import Foundation

/// Read-only, conservative metrics. A missing measurement stays missing rather
/// than being inferred from a workout prescription.
enum SessionMetrics {
    struct Weekly: Identifiable {
        let start: Date
        let sessions: [WorkoutSession]
        var id: Date { start }
        var count: Int { sessions.count }
        var recordedReps: Int? { sum(sessions.compactMap(\.recordedReps)) }
        var recordedVolume: Double? { sum(sessions.compactMap(\.recordedVolume)) }
        var completionRate: Double? {
            let eligible = sessions.filter { $0.resultsData != nil || $0.targetRounds > 0 }
            guard !eligible.isEmpty else { return nil }
            let values = eligible.compactMap(SessionMetrics.completionRate)
            return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
        }
    }

    static func weeks(sessions: [WorkoutSession], count: Int = 8, calendar: Calendar = .current, now: Date = .now) -> [Weekly] {
        guard count > 0 else { return [] }
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        return (0..<count).reversed().map { offset in
            let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeek) ?? thisWeek
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? now
            return Weekly(start: start, sessions: sessions.filter { $0.date >= start && $0.date < end })
        }
    }

    static func completionRate(_ session: WorkoutSession) -> Double? {
        if session.resultsData != nil {
            let results = session.results
            guard !results.isEmpty else { return nil }
            let target = session.definition?.blocks.reduce(0) { $0 + $1.targetSets } ?? results.count
            guard target > 0 else { return nil }
            return min(1, Double(results.filter(\.completed).count) / Double(target))
        }
        guard session.targetRounds > 0 else { return nil }
        return min(1, max(0, Double(session.completedRounds) / Double(session.targetRounds)))
    }

    static func movementReps(_ sessions: [WorkoutSession]) -> [String: Int] {
        sessions.flatMap(\.results).reduce(into: [:]) { totals, result in
            guard result.completed else { return }
            for movement in result.repetitions { totals[movement.name, default: 0] += movement.reps }
        }
    }

    static func movementVolume(_ sessions: [WorkoutSession]) -> [String: Double] {
        sessions.flatMap(\.results).reduce(into: [:]) { totals, result in
            guard result.completed else { return }
            for movement in result.repetitions { totals[movement.name, default: 0] += Double(movement.reps) * result.loadKg * Double(result.bells) }
        }
    }

    static func isComparablePace(_ lhs: WorkoutSession, _ rhs: WorkoutSession) -> Bool {
        guard lhs.isCompleted, rhs.isCompleted,
              let lhsDefinition = lhs.definition, let rhsDefinition = rhs.definition,
              lhsDefinition.comparisonKey == rhsDefinition.comparisonKey,
              lhsDefinition.blocks.allSatisfy({ $0.loadKg > 0 && $0.bells > 0 }),
              rhsDefinition.blocks.allSatisfy({ $0.loadKg > 0 && $0.bells > 0 }) else { return false }
        guard measuredDuration(lhs) != nil && measuredDuration(rhs) != nil else { return false }
        return [lhs, rhs].allSatisfy { session in
            session.sourceRaw != "manual" || session.results.contains { ($0.duration ?? 0) > 0 }
        }
    }

    static func measuredDuration(_ session: WorkoutSession) -> TimeInterval? {
        guard session.totalDuration.isFinite, session.totalDuration > 0 else { return nil }
        return session.totalDuration
    }

    private static func sum<T: BinaryInteger>(_ values: [T]) -> T? { values.isEmpty ? nil : values.reduce(0, +) }
    private static func sum(_ values: [Double]) -> Double? { values.isEmpty ? nil : values.reduce(0, +) }
}
