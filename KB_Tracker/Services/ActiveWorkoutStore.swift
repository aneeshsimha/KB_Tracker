import Foundation

enum WorkoutRunPhase: String, Codable {
    case getReady, working, rest, waitingNext, complete
}

/// A complete, independently decodable checkpoint. Dates, rather than tick counts, are
/// the source of truth so a suspended app can resume at the correct point.
struct ActiveWorkoutSnapshot: Codable {
    var id: UUID = UUID()
    var definition: WorkoutDefinition
    var programID: UUID?
    var startedAt: Date?
    var endedAt: Date?
    var phase: WorkoutRunPhase = .getReady
    var phaseStartedAt: Date?
    var blockIndex: Int = 0
    var setIndex: Int = 0
    var results: [WorkoutSetResult] = []
    var pausedAt: Date?
    var pausedDuration: TimeInterval = 0
    var isPartial = false
    var activeSetStartedAt: Date?
    var lastLoggedAt: Date?
    var notes = ""
    var difficulty: SessionDifficulty?
    var getReadySeconds: Int?
}

enum ActiveWorkoutStore {
    private static let key = "kb.activeWorkout.v1"
    private static let diagnosticKey = "kb.activeWorkout.recoveryError"
    private static var fileURL: URL? {
        if let override = ProcessInfo.processInfo.environment["KB_ACTIVE_WORKOUT_PATH"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }
        return try? FileManager.default.url(for: .applicationSupportDirectory,
                                            in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("KB_Tracker", isDirectory: true)
            .appendingPathComponent("active-workout-v1.json")
    }

    static func load() -> ActiveWorkoutSnapshot? {
        let defaults = UserDefaults.standard
        let diskData = fileURL.flatMap { try? Data(contentsOf: $0) }
        guard let data = diskData ?? defaults.data(forKey: key) else { return nil }
        guard
              let snapshot = try? JSONDecoder().decode(ActiveWorkoutSnapshot.self, from: data),
              snapshot.definition.validationError == nil,
              snapshot.definition.blocks.indices.contains(snapshot.blockIndex),
              snapshot.setIndex >= 0,
              snapshot.setIndex < snapshot.definition.blocks[snapshot.blockIndex].targetSets,
              snapshot.pausedDuration.isFinite, snapshot.pausedDuration >= 0
        else {
            defaults.set("The saved workout could not be restored. You can discard it and start again.", forKey: diagnosticKey)
            return nil
        }
        defaults.removeObject(forKey: diagnosticKey)
        if diskData == nil {
            if (try? save(snapshot)) != nil { defaults.removeObject(forKey: key) }
        }
        return snapshot
    }

    static func save(_ snapshot: ActiveWorkoutSnapshot) throws {
        if recoveryError() != nil, let url = fileURL, FileManager.default.fileExists(atPath: url.path) {
            throw CocoaError(.fileWriteFileExists)
        }
        let data = try JSONEncoder().encode(snapshot)
        guard let url = fileURL else { throw CocoaError(.fileNoSuchFile) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
    }

    static func clear() throws {
        if let url = fileURL, FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: diagnosticKey)
    }

    static func recoveryError() -> String? { UserDefaults.standard.string(forKey: diagnosticKey) }
}
