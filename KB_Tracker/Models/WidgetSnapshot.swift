import Foundation

struct WidgetPreset: Codable, Hashable, Identifiable {
    var id: String
    var name: String
}

struct WidgetSnapshot: Codable {
    static let group = "group.aniche-studios.KB-Tracker"
    static let key = "kb-widget-snapshot"
    var nextTitle: String = "Choose your next workout"
    var weeklySessions: Int = 0
    var presets: [WidgetPreset] = []
    var updatedAt: Date = Date()
    static func load() -> WidgetSnapshot {
        guard let data = UserDefaults(suiteName: group)?.data(forKey: key),
              let value = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        return value
    }
}
