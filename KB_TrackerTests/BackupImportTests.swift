import Foundation
import SwiftData
import Testing
@testable import KB_Tracker

@MainActor
@Suite(.serialized)
struct BackupImportTests {
    private func container() throws -> ModelContainer {
        let schema = Schema([WorkoutSession.self, WorkoutTemplate.self,
                             EquipmentRecord.self, TrainingProgram.self])
        return try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true,
                               cloudKitDatabase: .none)
        ])
    }

    @Test func swiftDataArchiveImportIsFaithfulIdempotentAndTransactional() throws {
        let sourceContainer = try container()
        let source = ModelContext(sourceContainer)
        source.autosaveEnabled = false

        var block = WorkoutBlock(name: "ABC", kind: .rounds,
                                 movements: [.init(name: "Clean", reps: 2),
                                             .init(name: "Press", reps: 1)],
                                 loadKg: 20, bells: 2, rounds: 1,
                                 workSeconds: 45, restSeconds: 60)
        block.movements[0].perSide = true
        let definition = WorkoutDefinition(name: "Imported ABC", workoutType: .abc,
                                           blocks: [block])

        let session = WorkoutSession(mode: .rounds, kettlebellType: .double,
                                     weight: 20, targetRounds: 1, restDuration: 60)
        session.date = Date(timeIntervalSinceReferenceDate: 100)
        session.endedAt = Date(timeIntervalSinceReferenceDate: 160)
        session.totalDuration = 60
        session.completedRounds = 1
        session.isCompleted = true
        session.notes = "source note"
        session.sourceRaw = "runner"
        session.difficulty = .manageable
        session.definition = definition
        session.results = [WorkoutSetResult(blockID: block.id, setIndex: 0, duration: 42,
                                            repetitions: [.init(name: "Clean", reps: 4),
                                                          .init(name: "Press", reps: 1)],
                                            loadKg: 20, bells: 2)]
        session.modifiedAt = Date(timeIntervalSinceReferenceDate: 200)

        let template = WorkoutTemplate(definition: definition, isFavorite: true)
        template.modifiedAt = Date(timeIntervalSinceReferenceDate: 201)
        let equipment = EquipmentRecord(weightKg: 20, count: 2)
        equipment.modifiedAt = Date(timeIntervalSinceReferenceDate: 202)
        let program = TrainingProgram()
        program.name = "Imported plan"
        program.nextIndex = 3
        program.decisionHistory = [ProgramDecision(sessionID: session.id,
                                                   date: Date(timeIntervalSinceReferenceDate: 150),
                                                   message: "Held target")]
        program.rescheduleHistory = [ProgramReschedule(
            plannedDate: Date(timeIntervalSinceReferenceDate: 300),
            movedDate: Date(timeIntervalSinceReferenceDate: 400))]
        program.modifiedAt = Date(timeIntervalSinceReferenceDate: 203)

        source.insert(session)
        source.insert(template)
        source.insert(equipment)
        source.insert(program)
        try source.save()

        let archive = try BackupService.archive(context: source)
        let data = try JSONEncoder().encode(archive)
        let targetContainer = try container()
        let targetPreviewContext = ModelContext(targetContainer)
        let preview = try BackupService.preview(data: data, context: targetPreviewContext)
        #expect(preview.newSessions == 1)
        #expect(preview.updates == 0)
        try BackupService.import(preview, context: targetPreviewContext)

        var check = ModelContext(targetContainer)
        var sessions = try check.fetch(FetchDescriptor<WorkoutSession>())
        var templates = try check.fetch(FetchDescriptor<WorkoutTemplate>())
        var equipmentRecords = try check.fetch(FetchDescriptor<EquipmentRecord>())
        var programs = try check.fetch(FetchDescriptor<TrainingProgram>())
        #expect(sessions.count == 1)
        #expect(templates.count == 1)
        #expect(equipmentRecords.count == 1)
        #expect(programs.count == 1)
        #expect(sessions[0].definition == definition)
        #expect(sessions[0].results == session.results)
        #expect(sessions[0].notes == "source note")
        #expect(sessions[0].difficulty == .manageable)
        #expect(templates[0].definition == definition)
        #expect(templates[0].isFavorite)
        #expect(equipmentRecords[0].weightKg == 20)
        #expect(equipmentRecords[0].count == 2)
        #expect(programs[0].decisionHistory.first?.message == "Held target")
        #expect(programs[0].rescheduleHistory.first?.movedDate == Date(timeIntervalSinceReferenceDate: 400))

        // Re-importing identical JSON updates in place rather than duplicating.
        let secondPreview = try BackupService.preview(data: data, context: check)
        #expect(secondPreview.newSessions == 0)
        #expect(secondPreview.updates == 1)
        try BackupService.import(secondPreview, context: check)
        check = ModelContext(targetContainer)
        #expect(try check.fetchCount(FetchDescriptor<WorkoutSession>()) == 1)
        #expect(try check.fetchCount(FetchDescriptor<WorkoutTemplate>()) == 1)
        #expect(try check.fetchCount(FetchDescriptor<EquipmentRecord>()) == 1)
        #expect(try check.fetchCount(FetchDescriptor<TrainingProgram>()) == 1)

        // A newer local edit wins over the older backup record.
        let local = try #require(try check.fetch(FetchDescriptor<WorkoutSession>()).first)
        local.notes = "newer local note"
        local.modifiedAt = Date(timeIntervalSinceReferenceDate: 500)
        try check.save()
        let olderPreview = try BackupService.preview(data: data, context: check)
        try BackupService.import(olderPreview, context: check)
        check = ModelContext(targetContainer)
        #expect(try check.fetch(FetchDescriptor<WorkoutSession>()).first?.notes == "newer local note")

        // Conversely, a newer backup edit replaces the older local record.
        var newerArchive = archive
        newerArchive.sessions[0].notes = "newer imported note"
        newerArchive.sessions[0].modifiedAt = Date(timeIntervalSinceReferenceDate: 600)
        let newerData = try JSONEncoder().encode(newerArchive)
        let newerPreview = try BackupService.preview(data: newerData, context: check)
        try BackupService.import(newerPreview, context: check)
        check = ModelContext(targetContainer)
        #expect(try check.fetch(FetchDescriptor<WorkoutSession>()).first?.notes == "newer imported note")

        // Validation failure occurs in the isolated import context and preserves data.
        var invalidArchive = archive
        invalidArchive.sessions.append(archive.sessions[0])
        let invalidPreview = BackupService.Preview(archive: invalidArchive,
                                                   newSessions: 0, updates: 2)
        #expect(throws: BackupService.Error.self) {
            try BackupService.import(invalidPreview, context: check)
        }
        check = ModelContext(targetContainer)
        sessions = try check.fetch(FetchDescriptor<WorkoutSession>())
        templates = try check.fetch(FetchDescriptor<WorkoutTemplate>())
        equipmentRecords = try check.fetch(FetchDescriptor<EquipmentRecord>())
        programs = try check.fetch(FetchDescriptor<TrainingProgram>())
        #expect(sessions.count == 1 && sessions[0].notes == "newer imported note")
        #expect(templates.count == 1)
        #expect(equipmentRecords.count == 1)
        #expect(programs.count == 1)
    }
}
