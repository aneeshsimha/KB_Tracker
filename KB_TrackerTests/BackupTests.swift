import Testing
import Foundation
@testable import KB_Tracker

struct BackupTests {
    @Test func archiveRoundTripsCodableSessionData() throws {
        let session = WorkoutSession()
        session.notes = "quoted, note"
        let definition = WorkoutDefinition(name: "Saved", blocks: [WorkoutBlock()])
        let template = WorkoutTemplate(definition: definition, isFavorite: true)
        let equipment = EquipmentRecord(weightKg: 20, count: 2)
        let program = TrainingProgram()
        program.decisionHistory = [ProgramDecision(message: "Held target")]
        program.rescheduleHistory = [ProgramReschedule(plannedDate: .now, movedDate: .now)]
        let programRecord = BackupService.ProgramRecord(backup: program)
        let archive = BackupService.Archive(sessions: [.init(session)], templates: [.init(template)], equipment: [.init(equipment)], programs: [programRecord])
        let decoded = try JSONDecoder().decode(BackupService.Archive.self, from: JSONEncoder().encode(archive))
        #expect(decoded.version == BackupService.currentVersion)
        #expect(decoded.sessions.first?.notes == "quoted, note")
        #expect(decoded.templates.first?.definitionData == template.definitionData)
        #expect(decoded.equipment.first?.weightKg == 20)
        #expect(decoded.programs.first?.rescheduleHistoryData == program.rescheduleHistoryData)
    }

    @Test func backupRejectsDuplicateAndCorruptNestedRecords() throws {
        let session = WorkoutSession()
        let duplicate = BackupService.Archive(sessions: [.init(session), .init(session)])
        #expect(throws: BackupService.Error.self) { try BackupService.validate(duplicate) }
        var corrupt = BackupService.Archive(sessions: [.init(session)])
        corrupt.sessions[0].definitionData = Data("not-json".utf8)
        #expect(throws: BackupService.Error.self) { try BackupService.validate(corrupt) }
        var mismatched = BackupService.Archive(sessions: [.init(session)])
        let definition = WorkoutDefinition(name: "One", blocks: [WorkoutBlock()])
        mismatched.sessions[0].definitionData = try JSONEncoder().encode(definition)
        mismatched.sessions[0].resultsData = try JSONEncoder().encode([WorkoutSetResult(blockID: UUID(), setIndex: 0, loadKg: 16, bells: 1)])
        #expect(throws: BackupService.Error.self) { try BackupService.validate(mismatched) }
    }

    @Test func backupRejectsMalformedProgramOverrideAndInvalidResultSlots() throws {
        let program = TrainingProgram()
        var record = BackupService.ProgramRecord(backup: program)
        record.nextOverrideData = Data("bad-definition".utf8)
        #expect(throws: BackupService.Error.self) { try BackupService.validate(.init(programs: [record])) }

        let block = WorkoutBlock()
        let session = WorkoutSession()
        session.definition = WorkoutDefinition(name: "One", blocks: [block])
        session.results = [WorkoutSetResult(blockID: block.id, setIndex: block.targetSets, repetitions: [.init(name: "Swing", reps: -1)], loadKg: 16, bells: 1)]
        #expect(throws: BackupService.Error.self) { try BackupService.validate(.init(sessions: [.init(session)])) }
    }
}
