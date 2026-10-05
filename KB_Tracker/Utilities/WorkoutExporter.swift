// WorkoutExporter.swift
// KB_Tracker
//
// Converts WorkoutSession history to CSV for share-sheet export.

import Foundation

enum WorkoutExporter {
    static func csv(from sessions: [WorkoutSession]) -> String {
        let header = "session_id,date,modified_at,source,status,workout_name,workout_type,mode,kb_type,weight_kg,target_rounds,completed_rounds,total_duration_s,rest_duration_s,set_times_s,block_index,block_name,block_kind,movement,reps,load_kg,bells,set_duration_s,set_completed,notes,health_workout_id"
        let rows = sessions.map { row(for: $0) }
        return ([header] + rows).joined(separator: "\n")
    }

    private static let isoFormatter: ISO8601DateFormatter = ISO8601DateFormatter()

    private static func row(for s: WorkoutSession) -> String {
        let base = [s.id.uuidString, isoFormatter.string(from: s.date), isoFormatter.string(from: s.modifiedAt), s.sourceRaw, s.isCompleted ? "completed" : "incomplete", s.displayTitle, s.workoutType.rawValue, s.mode.rawValue, s.kettlebellType.rawValue, "\(s.weight)", "\(s.targetRounds)", "\(s.completedRounds)", String(format: "%.2f", s.totalDuration), s.restDuration.map(String.init) ?? "", s.setTimes.map { String(format: "%.2f", $0) }.joined(separator: "|")]
        let blocks = s.definition?.blocks ?? []
        let results = s.results
        let details: [[String]] = results.isEmpty ? [["", "", "", "", "", "", "", "", ""]] : results.map { result in
            let block = blocks.first { $0.id == result.blockID }
            let reps = result.repetitions.map { "\($0.name):\($0.reps)" }.joined(separator: "|")
            return [block.flatMap { blocks.firstIndex(of: $0) }.map(String.init) ?? "", block?.name ?? "", block?.kind.rawValue ?? "", result.repetitions.map(\.name).joined(separator: "|") , reps, String(result.loadKg), String(result.bells), result.duration.map(String.init) ?? "", result.completed ? "true" : "false"]
        }
        return details.map { fields in (base + fields + [s.notes ?? "", s.healthWorkoutID ?? ""]).map(csvField).joined(separator: ",") }.joined(separator: "\n")
    }

    private static func csvField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}
