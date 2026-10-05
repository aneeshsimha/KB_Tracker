import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

enum BackupService {
    static let currentVersion = 1

    struct Archive: Codable {
        var version: Int = currentVersion
        var exportedAt: Date = .now
        var sessions: [SessionRecord] = []
        var templates: [TemplateRecord] = []
        var equipment: [EquipmentBackupRecord] = []
        var programs: [ProgramRecord] = []
    }

    struct SessionRecord: Codable, Identifiable {
        var id: UUID; var date: Date; var modeRaw: String; var kettlebellTypeRaw: String; var weight: Int; var targetRounds: Int; var completedRounds: Int; var totalDuration: TimeInterval; var restDuration: Int?; var setTimes: [TimeInterval]; var notes: String?; var isCompleted: Bool; var workoutTypeRaw: String; var targetLadders: Int; var ladderReps: [Int]; var schemaVersion: Int; var definitionData: Data?; var resultsData: Data?; var endedAt: Date?; var pausedDuration: TimeInterval; var sourceRaw: String; var difficultyRaw: String?; var programID: UUID?; var modifiedAt: Date; var healthExportedAt: Date?; var healthWorkoutID: String?; var healthExportError: String?
        init(_ s: WorkoutSession) { id = s.id; date = s.date; modeRaw = s.mode.rawValue; kettlebellTypeRaw = s.kettlebellType.rawValue; weight = s.weight; targetRounds = s.targetRounds; completedRounds = s.completedRounds; totalDuration = s.totalDuration; restDuration = s.restDuration; setTimes = s.setTimes; notes = s.notes; isCompleted = s.isCompleted; workoutTypeRaw = s.workoutType.rawValue; targetLadders = s.targetLadders; ladderReps = s.ladderReps; schemaVersion = s.schemaVersion; definitionData = s.definitionData; resultsData = s.resultsData; endedAt = s.endedAt; pausedDuration = s.pausedDuration; sourceRaw = s.sourceRaw; difficultyRaw = s.difficultyRaw; programID = s.programID; modifiedAt = s.modifiedAt; healthExportedAt = s.healthExportedAt; healthWorkoutID = s.healthWorkoutID; healthExportError = s.healthExportError }
        func apply(to s: WorkoutSession) { s.id = id; s.date = date; s.mode = WorkoutMode(rawValue: modeRaw) ?? .emom; s.kettlebellType = KBType(rawValue: kettlebellTypeRaw) ?? .single; s.weight = weight; s.targetRounds = targetRounds; s.completedRounds = completedRounds; s.totalDuration = totalDuration; s.restDuration = restDuration; s.setTimes = setTimes; s.notes = notes; s.isCompleted = isCompleted; s.workoutType = WorkoutType(rawValue: workoutTypeRaw) ?? .custom; s.targetLadders = targetLadders; s.ladderReps = ladderReps; s.schemaVersion = schemaVersion; s.definitionData = definitionData; s.resultsData = resultsData; s.endedAt = endedAt; s.pausedDuration = pausedDuration; s.sourceRaw = sourceRaw; s.difficultyRaw = difficultyRaw; s.programID = programID; s.modifiedAt = modifiedAt; s.healthExportedAt = healthExportedAt; s.healthWorkoutID = healthWorkoutID; s.healthExportError = healthExportError }
    }
    struct TemplateRecord: Codable, Identifiable { var id: UUID; var name: String; var definitionData: Data; var isFavorite: Bool; var modifiedAt: Date; init(_ value: WorkoutTemplate) { id = value.id; name = value.name; definitionData = value.definitionData; isFavorite = value.isFavorite; modifiedAt = value.modifiedAt } }
    struct EquipmentBackupRecord: Codable, Identifiable { var id: UUID; var weightKg: Double; var count: Int; var modifiedAt: Date; init(_ value: EquipmentRecord) { id = value.id; weightKg = value.weightKg; count = value.count; modifiedAt = value.modifiedAt } }
    struct ProgramRecord: Codable, Identifiable {
        var rescheduleHistoryData: Data = Data("[]".utf8)
        var id: UUID; var name: String; var isActive: Bool; var weekdaysData: Data; var remindersEnabled: Bool; var reminderHour: Int; var reminderMinute: Int; var autoProgress: Bool; var usesTemplates: Bool; var templateDefinitionsData: Data; var nextIndex: Int; var nextOverrideData: Data?; var rescheduledDate: Date?; var abcModeRaw: String; var abcMinutes: Int; var abcRounds: Int; var abcStartMinutes: Int; var abcStartRounds: Int; var abcRestSeconds: Int; var abcWeightKg: Double; var abcBells: Int; var pressLadders: Int; var pressStartLadders: Int; var pressWeightKg: Double; var pressBells: Int; var abcSuccessStreak: Int; var abcStruggleStreak: Int; var pressSuccessStreak: Int; var pressStruggleStreak: Int; var abcStreakKey: String; var pressStreakKey: String; var streakTargetRaw: String; var decisionHistoryData: Data; var pendingBellTargetRaw: String; var evaluatedSessionIDsData: Data; var lastDecision: String; var pendingBellApproval: Bool; var modifiedAt: Date
        init(_ p: TrainingProgram) { id=p.id; name=p.name; isActive=p.isActive; weekdaysData=p.weekdaysData; remindersEnabled=p.remindersEnabled; reminderHour=p.reminderHour; reminderMinute=p.reminderMinute; autoProgress=p.autoProgress; usesTemplates=p.usesTemplates; templateDefinitionsData=p.templateDefinitionsData; nextIndex=p.nextIndex; nextOverrideData=p.nextOverrideData; rescheduledDate=p.rescheduledDate; abcModeRaw=p.abcModeRaw; abcMinutes=p.abcMinutes; abcRounds=p.abcRounds; abcStartMinutes=p.abcStartMinutes; abcStartRounds=p.abcStartRounds; abcRestSeconds=p.abcRestSeconds; abcWeightKg=p.abcWeightKg; abcBells=p.abcBells; pressLadders=p.pressLadders; pressStartLadders=p.pressStartLadders; pressWeightKg=p.pressWeightKg; pressBells=p.pressBells; abcSuccessStreak=p.abcSuccessStreak; abcStruggleStreak=p.abcStruggleStreak; pressSuccessStreak=p.pressSuccessStreak; pressStruggleStreak=p.pressStruggleStreak; abcStreakKey=p.abcStreakKey; pressStreakKey=p.pressStreakKey; streakTargetRaw=p.streakTargetRaw; decisionHistoryData=p.decisionHistoryData; pendingBellTargetRaw=p.pendingBellTargetRaw; evaluatedSessionIDsData=p.evaluatedSessionIDsData; lastDecision=p.lastDecision; pendingBellApproval=p.pendingBellApproval; modifiedAt=p.modifiedAt }
    }
    struct Preview { let archive: Archive; let newSessions: Int; let updates: Int }
    enum Error: LocalizedError { case unsupportedVersion, invalid(String); var errorDescription: String? { switch self { case .unsupportedVersion: return "This backup uses an unsupported version."; case .invalid(let value): return value } } }

    static func archive(context: ModelContext) throws -> Archive {
        let programs = try context.fetch(FetchDescriptor<TrainingProgram>()).map { program -> ProgramRecord in
            var record = ProgramRecord(program)
            record.rescheduleHistoryData = program.rescheduleHistoryData
            return record
        }
        return Archive(sessions: try context.fetch(FetchDescriptor<WorkoutSession>()).map(SessionRecord.init), templates: try context.fetch(FetchDescriptor<WorkoutTemplate>()).map(TemplateRecord.init), equipment: try context.fetch(FetchDescriptor<EquipmentRecord>()).map(EquipmentBackupRecord.init), programs: programs)
    }
    static func preview(data: Data, context: ModelContext) throws -> Preview {
        let archive = try JSONDecoder().decode(Archive.self, from: data); try validate(archive)
        let existing = Set(try context.fetch(FetchDescriptor<WorkoutSession>()).map(\.id))
        return Preview(archive: archive, newSessions: archive.sessions.filter { !existing.contains($0.id) }.count, updates: archive.sessions.filter { existing.contains($0.id) }.count)
    }
    /// Validates the complete file before changing the model context. Conflicts use
    /// the stable UUID and the most recently modified record wins.
    @MainActor static func `import`(_ preview: Preview, context: ModelContext) throws {
        // Work in an isolated context: a failed file must never roll back edits
        // the user has made in the UI's context but not saved yet.
        let importContext = ModelContext(context.container)
        importContext.autosaveEnabled = false
        try apply(preview, context: importContext)
    }

    @MainActor private static func apply(_ preview: Preview, context: ModelContext) throws {
        try validate(preview.archive)
        let existing = try context.fetch(FetchDescriptor<WorkoutSession>())
        var healthOwners: [String: UUID] = [:]
        for session in existing { if let healthID = session.healthWorkoutID { healthOwners[healthID] = session.id } }
        for record in preview.archive.sessions {
            if let healthID = record.healthWorkoutID, let owner = healthOwners[healthID], owner != record.id {
                throw Error.invalid("Apple Health workout \(healthID) already belongs to another session.")
            }
        }
        var byID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { max($0, $1, by: { $0.modifiedAt < $1.modifiedAt }) })
        for record in preview.archive.sessions {
            if let session = byID[record.id] { if record.modifiedAt > session.modifiedAt { record.apply(to: session) } }
            else { let session = WorkoutSession(); record.apply(to: session); context.insert(session); byID[record.id] = session }
        }
        var templates = Dictionary(try context.fetch(FetchDescriptor<WorkoutTemplate>()).map { ($0.id, $0) }, uniquingKeysWith: { max($0, $1, by: { $0.modifiedAt < $1.modifiedAt }) })
        for r in preview.archive.templates { let isNew = templates[r.id] == nil; let m = templates[r.id] ?? WorkoutTemplate(definition: WorkoutDefinition(name: r.name, blocks: [WorkoutBlock()])); if isNew { context.insert(m); templates[r.id] = m }; if isNew || r.modifiedAt > m.modifiedAt { m.id=r.id; m.name=r.name; m.definitionData=r.definitionData; m.isFavorite=r.isFavorite; m.modifiedAt=r.modifiedAt } }
        var equipment = Dictionary(try context.fetch(FetchDescriptor<EquipmentRecord>()).map { ($0.id, $0) }, uniquingKeysWith: { max($0, $1, by: { $0.modifiedAt < $1.modifiedAt }) })
        for r in preview.archive.equipment { let isNew = equipment[r.id] == nil; let m = equipment[r.id] ?? EquipmentRecord(weightKg: r.weightKg, count: r.count); if isNew { context.insert(m); equipment[r.id] = m }; if isNew || r.modifiedAt > m.modifiedAt { m.id=r.id; m.weightKg=r.weightKg; m.count=r.count; m.modifiedAt=r.modifiedAt } }
        var programs = Dictionary(try context.fetch(FetchDescriptor<TrainingProgram>()).map { ($0.id, $0) }, uniquingKeysWith: { max($0, $1, by: { $0.modifiedAt < $1.modifiedAt }) })
        for r in preview.archive.programs { let isNew = programs[r.id] == nil; let p = programs[r.id] ?? TrainingProgram(); if isNew { context.insert(p); programs[r.id] = p }; if isNew || r.modifiedAt > p.modifiedAt { apply(r, to: p) } }
        // `rescheduleHistoryData` was added after the original record shape;
        // copy it after the normal newest-record merge has selected its winner.
        for record in preview.archive.programs {
            if let program = programs[record.id], program.modifiedAt == record.modifiedAt {
                program.rescheduleHistoryData = record.rescheduleHistoryData
            }
        }
        do { try context.save() } catch { context.rollback(); throw error }
    }
    private static func apply(_ r: ProgramRecord, to p: TrainingProgram) { p.id=r.id;p.name=r.name;p.isActive=r.isActive;p.weekdaysData=r.weekdaysData;p.remindersEnabled=r.remindersEnabled;p.reminderHour=r.reminderHour;p.reminderMinute=r.reminderMinute;p.autoProgress=r.autoProgress;p.usesTemplates=r.usesTemplates;p.templateDefinitionsData=r.templateDefinitionsData;p.nextIndex=r.nextIndex;p.nextOverrideData=r.nextOverrideData;p.rescheduledDate=r.rescheduledDate;p.abcModeRaw=r.abcModeRaw;p.abcMinutes=r.abcMinutes;p.abcRounds=r.abcRounds;p.abcStartMinutes=r.abcStartMinutes;p.abcStartRounds=r.abcStartRounds;p.abcRestSeconds=r.abcRestSeconds;p.abcWeightKg=r.abcWeightKg;p.abcBells=r.abcBells;p.pressLadders=r.pressLadders;p.pressStartLadders=r.pressStartLadders;p.pressWeightKg=r.pressWeightKg;p.pressBells=r.pressBells;p.abcSuccessStreak=r.abcSuccessStreak;p.abcStruggleStreak=r.abcStruggleStreak;p.pressSuccessStreak=r.pressSuccessStreak;p.pressStruggleStreak=r.pressStruggleStreak;p.abcStreakKey=r.abcStreakKey;p.pressStreakKey=r.pressStreakKey;p.streakTargetRaw=r.streakTargetRaw;p.decisionHistoryData=r.decisionHistoryData;p.pendingBellTargetRaw=r.pendingBellTargetRaw;p.evaluatedSessionIDsData=r.evaluatedSessionIDsData;p.lastDecision=r.lastDecision;p.pendingBellApproval=r.pendingBellApproval;p.modifiedAt=r.modifiedAt }
    private static func validate(_ archive: Archive) throws {
        guard archive.version == currentVersion else { throw Error.unsupportedVersion }
        guard Set(archive.sessions.map(\.id)).count == archive.sessions.count else { throw Error.invalid("The backup contains duplicate session IDs.") }
        guard Set(archive.templates.map(\.id)).count == archive.templates.count, Set(archive.equipment.map(\.id)).count == archive.equipment.count, Set(archive.programs.map(\.id)).count == archive.programs.count else { throw Error.invalid("The backup contains duplicate record IDs.") }
        let healthIDs = archive.sessions.compactMap(\.healthWorkoutID); guard Set(healthIDs).count == healthIDs.count else { throw Error.invalid("The backup contains duplicate Apple Health workout IDs.") }
        for s in archive.sessions {
            guard WorkoutMode(rawValue: s.modeRaw) != nil, KBType(rawValue: s.kettlebellTypeRaw) != nil, WorkoutType(rawValue: s.workoutTypeRaw) != nil, s.schemaVersion == 1, s.totalDuration.isFinite, s.totalDuration >= 0, s.weight >= 0, s.targetRounds >= 0, s.completedRounds >= 0 else { throw Error.invalid("A session has invalid measurements.") }
            if let data = s.definitionData { guard let definition = try? JSONDecoder().decode(WorkoutDefinition.self, from: data), definition.validationError == nil else { throw Error.invalid("A workout definition is invalid.") }; if let results = s.resultsData { guard let decoded = try? JSONDecoder().decode([WorkoutSetResult].self, from: results), decoded.allSatisfy({ result in definition.blocks.contains(where: { block in block.id == result.blockID }) }) else { throw Error.invalid("Workout results are invalid.") } } }
        }
        for t in archive.templates { guard let definition = try? JSONDecoder().decode(WorkoutDefinition.self, from: t.definitionData), definition.validationError == nil else { throw Error.invalid("A template is invalid.") } }
        for e in archive.equipment where !e.weightKg.isFinite || e.weightKg <= 0 || e.count < 1 { throw Error.invalid("Equipment is invalid.") }
    }
}

struct KBBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(archive: BackupService.Archive) throws { data = try JSONEncoder().encode(archive) }
    init(configuration: ReadConfiguration) throws { guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }; self.data = data }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { .init(regularFileWithContents: data) }
}
