import Foundation
import SwiftData

@MainActor enum SessionRepository {
    static func save(_ session: WorkoutSession, context: ModelContext) throws {
        let id = session.id
        let existing = try context.fetch(FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == id }))
        let isNew = existing.isEmpty
        if isNew { context.insert(session) }
        else if let stored = existing.first, stored !== session {
            // A failed save can leave the first insertion in this context. Retry
            // persistence before allowing the caller to clear its recovery file.
            try context.save()
            return
        }
        session.modifiedAt = Date()
        if isNew, let programID = session.programID {
            let programs = try context.fetch(FetchDescriptor<TrainingProgram>())
            if let program = programs.first(where: { $0.id == programID }) {
                ProgramService.evaluate(session: session, program: program)
            }
        }
        try context.save()
        WidgetSnapshotService.refresh(context: context)
        if let programID = session.programID,
           let program = try context.fetch(FetchDescriptor<TrainingProgram>()).first(where: { $0.id == programID && $0.isActive && $0.remindersEnabled }) {
            Task { await NotificationService.scheduleProgram(days: program.weekdays, hour: program.reminderHour, minute: program.reminderMinute, override: program.rescheduledDate) }
        }
        if UserDefaults.standard.bool(forKey: "kb_health_auto") {
            Task { @MainActor in
                _ = await HealthKitService.save(session)
                try? context.save()
            }
        }
    }

    static func delete(_ session: WorkoutSession, context: ModelContext) throws {
        context.delete(session)
        try context.save()
        WidgetSnapshotService.refresh(context: context)
    }

    /// CloudKit does not enforce unique UUIDs; retain the most recently edited copy.
    static func reconcileDuplicates(context: ModelContext) throws {
        var seen = Set<UUID>()
        for session in try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)])) {
            if !seen.insert(session.id).inserted { context.delete(session) }
        }
        seen.removeAll()
        for template in try context.fetch(FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)])) {
            if !seen.insert(template.id).inserted { context.delete(template) }
        }
        seen.removeAll()
        for equipment in try context.fetch(FetchDescriptor<EquipmentRecord>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)])) {
            if !seen.insert(equipment.id).inserted { context.delete(equipment) }
        }
        seen.removeAll()
        for program in try context.fetch(FetchDescriptor<TrainingProgram>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)])) {
            if !seen.insert(program.id).inserted { context.delete(program) }
        }
        if context.hasChanges { try context.save() }
    }
}
