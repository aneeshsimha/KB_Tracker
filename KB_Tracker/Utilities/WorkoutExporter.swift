// WorkoutExporter.swift
// KB_Tracker
//
// Converts WorkoutSession history to CSV for share-sheet export.

import Foundation

enum WorkoutExporter {
    static func csv(from sessions: [WorkoutSession]) -> String {
        let header = "date,mode,workout_type,kb_type,weight_kg,target_rounds,completed_rounds,total_duration_s,rest_duration_s,set_times_s,is_completed,notes"
        let rows = sessions.map { row(for: $0) }
        return ([header] + rows).joined(separator: "\n")
    }

    private static let isoFormatter: ISO8601DateFormatter = ISO8601DateFormatter()

    private static func row(for s: WorkoutSession) -> String {
        let setTimesStr = s.setTimes.map { String(format: "%.2f", $0) }.joined(separator: "|")
        let fields: [String] = [
            isoFormatter.string(from: s.date),
            s.mode.rawValue,
            s.workoutType.rawValue,
            s.kettlebellType.rawValue,
            "\(s.weight)",
            "\(s.targetRounds)",
            "\(s.completedRounds)",
            String(format: "%.1f", s.totalDuration),
            s.restDuration.map { "\($0)" } ?? "",
            setTimesStr,
            s.isCompleted ? "true" : "false",
            s.notes ?? ""
        ]
        return fields.map { csvField($0) }.joined(separator: ",")
    }

    private static func csvField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}
