import Foundation
import SwiftData
import WidgetKit

@MainActor enum WidgetSnapshotService {
    static func refresh(context: ModelContext) {
        guard let sessions = try? context.fetch(FetchDescriptor<WorkoutSession>()),
              let templates = try? context.fetch(FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)])),
              let programs = try? context.fetch(FetchDescriptor<TrainingProgram>()) else { return }
        let week = Calendar.current.dateInterval(of: .weekOfYear, for: Date())
        let title = programs.filter(\.isActive).sorted(by: { $0.modifiedAt > $1.modifiedAt }).first.map { ProgramService.nextDefinition(program: $0).name } ?? "Choose your next workout"
        let value = WidgetSnapshot(nextTitle: title, weeklySessions: sessions.filter { week?.contains($0.date) == true }.count, presets: templates.filter(\.isFavorite).map { WidgetPreset(id: $0.id.uuidString, name: $0.name) })
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults(suiteName: WidgetSnapshot.group)?.set(data, forKey: WidgetSnapshot.key)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
