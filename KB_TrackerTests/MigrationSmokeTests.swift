import Testing
import Foundation
import SwiftData
@testable import KB_Tracker

/// Opens a store written by the pre-definition session model. This is a smoke
/// test for SwiftData's additive lightweight migration; it intentionally does
/// not introduce a production VersionedSchema.
struct MigrationSmokeTests {
    @Test @MainActor func additiveSessionMigrationPreservesLegacyHistory() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("kb-migration-\(UUID().uuidString).store")
        defer {
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-shm"))
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-wal"))
        }
        let abcID = UUID(), pressID = UUID()
        do {
            let legacySchema = Schema([LegacySessionSchema.WorkoutSession.self])
            let legacy = try ModelContainer(for: legacySchema, configurations: [ModelConfiguration(schema: legacySchema, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(legacy)
            context.insert(LegacySessionSchema.WorkoutSession(id: abcID, notes: "legacy ABC", ladders: [], type: "abc"))
            context.insert(LegacySessionSchema.WorkoutSession(id: pressID, notes: "legacy press", ladders: [20, 15], type: "press"))
            try context.save()
        }
        let schema = Schema([WorkoutSession.self, WorkoutTemplate.self, EquipmentRecord.self, TrainingProgram.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
        let sessions = try ModelContext(container).fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.count == 2)
        #expect(sessions.first(where: { $0.id == abcID })?.notes == "legacy ABC")
        #expect(sessions.first(where: { $0.id == pressID })?.ladderReps == [20, 15])
        #expect(sessions.allSatisfy { $0.definition == nil && $0.results.isEmpty && $0.sourceRaw == "legacy" })
    }
}

enum LegacySessionSchema: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [WorkoutSession.self] }

    @Model final class WorkoutSession {
        var id: UUID = UUID(); var date: Date = Date(); var modeRaw = "emom"; var kettlebellTypeRaw = "double"; var weight = 20
        var targetRounds = 20; var completedRounds = 0; var totalDuration: TimeInterval = 0; var restDuration: Int? = nil
        var setTimes: [TimeInterval] = []; var notes: String? = nil; var isCompleted = false; var workoutTypeRaw = "abc"
        var targetLadders = 0; var ladderReps: [Int] = []
        init(id: UUID, notes: String, ladders: [Int], type: String) { self.id = id; self.notes = notes; ladderReps = ladders; workoutTypeRaw = type }
    }
}
