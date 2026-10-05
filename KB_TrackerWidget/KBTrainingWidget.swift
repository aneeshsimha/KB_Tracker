import SwiftUI
import WidgetKit

struct TrainingEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}
struct TrainingProvider: TimelineProvider {
    func placeholder(in context: Context) -> TrainingEntry { .init(date: Date(), snapshot: .init()) }
    func getSnapshot(in context: Context, completion: @escaping (TrainingEntry) -> Void) { completion(.init(date: Date(), snapshot: .load())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TrainingEntry>) -> Void) {
        completion(Timeline(entries: [.init(date: Date(), snapshot: .load())], policy: .after(Date().addingTimeInterval(1800))))
    }
}
struct KBTrainingWidget: Widget {
    let kind = "KBTrainingWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrainingProvider()) { entry in
            VStack(alignment: .leading, spacing: 10) {
                Text("KB Tracker").font(.caption).foregroundStyle(.secondary)
                Link(destination: URL(string: "kbtracker://next")!) {
                    Text(entry.snapshot.nextTitle).font(.headline).lineLimit(2)
                }
                Spacer(minLength: 0)
                HStack {
                    Text("\(entry.snapshot.weeklySessions) this week").font(.caption.monospacedDigit())
                    Spacer()
                    if let preset = entry.snapshot.presets.first,
                       let url = URL(string: "kbtracker://preset/\(preset.id)") {
                        Link(destination: url) { Label(preset.name, systemImage: "star.fill").font(.caption).lineLimit(1) }
                    }
                }
            }
            .containerBackground(.black, for: .widget)
            .foregroundStyle(.white)
        }
        .configurationDisplayName("Your training")
        .description("Your next workout, weekly sessions, and favorite preset.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
