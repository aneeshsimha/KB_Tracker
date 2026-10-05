import Foundation
import AppIntents

struct WorkoutLaunchRequest: Codable {
    enum Action: String, Codable { case next, repeatLast, preset }
    var action: Action
    var presetID: String? = nil
    static func enqueue(_ request: Self) {
        UserDefaults.standard.set(try? JSONEncoder().encode(request), forKey: "kb-launch-request")
    }
    static func consume() -> Self? {
        guard let data = UserDefaults.standard.data(forKey: "kb-launch-request") else { return nil }
        UserDefaults.standard.removeObject(forKey: "kb-launch-request")
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

struct PresetEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Workout preset"
    static var defaultQuery = PresetQuery()
    var id: String
    var name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}
struct PresetQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [PresetEntity] {
        WidgetSnapshot.load().presets.filter { identifiers.contains($0.id) }.map { PresetEntity(id: $0.id, name: $0.name) }
    }
    func suggestedEntities() async throws -> [PresetEntity] {
        WidgetSnapshot.load().presets.map { PresetEntity(id: $0.id, name: $0.name) }
    }
}
struct StartPresetIntent: AppIntent {
    static var title: LocalizedStringResource = "Start workout preset"
    static var openAppWhenRun = true
    @Parameter(title: "Preset") var preset: PresetEntity
    @MainActor func perform() async throws -> some IntentResult {
        WorkoutLaunchRequest.enqueue(.init(action: .preset, presetID: preset.id))
        return .result()
    }
}
struct RepeatWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Repeat last workout"
    static var openAppWhenRun = true
    @MainActor func perform() async throws -> some IntentResult {
        WorkoutLaunchRequest.enqueue(.init(action: .repeatLast))
        return .result()
    }
}
struct NextWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Open next workout"
    static var openAppWhenRun = true
    @MainActor func perform() async throws -> some IntentResult {
        WorkoutLaunchRequest.enqueue(.init(action: .next))
        return .result()
    }
}
struct KBShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: NextWorkoutIntent(), phrases: ["Open my next workout in \(.applicationName)"], shortTitle: "Next workout", systemImageName: "figure.strengthtraining.traditional")
        AppShortcut(intent: RepeatWorkoutIntent(), phrases: ["Repeat my workout in \(.applicationName)"], shortTitle: "Repeat workout", systemImageName: "arrow.counterclockwise")
        AppShortcut(intent: StartPresetIntent(), phrases: ["Start a preset in \(.applicationName)"], shortTitle: "Start preset", systemImageName: "star")
    }
}
