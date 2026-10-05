import Foundation
import SwiftData

struct ProgramDecision: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var sessionID: UUID? = nil
    var date: Date = Date()
    var message: String
}

struct ProgramReschedule: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var plannedDate: Date
    var movedDate: Date
}

/// One active training plan. Codable collections are stored as data for CloudKit compatibility.
@Model final class TrainingProgram {
    var id: UUID = UUID()
    var name: String = "ABC + Press"
    var isActive: Bool = true
    var weekdaysData: Data = Data("[2,4,6]".utf8)
    var remindersEnabled: Bool = false
    var reminderHour: Int = 8
    var reminderMinute: Int = 0
    var autoProgress: Bool = true
    var usesTemplates: Bool = false
    var templateDefinitionsData: Data = Data("[]".utf8)
    var nextIndex: Int = 0
    var nextOverrideData: Data? = nil
    var rescheduledDate: Date? = nil
    var abcModeRaw: String = WorkoutMode.emom.rawValue
    var abcMinutes: Int = 10
    var abcRounds: Int = 10
    var abcStartMinutes: Int = 10
    var abcStartRounds: Int = 10
    var abcRestSeconds: Int = 60
    var abcWeightKg: Double = 16
    var abcBells: Int = 2
    var pressLadders: Int = 3
    var pressStartLadders: Int = 3
    var pressWeightKg: Double = 16
    var pressBells: Int = 1
    var abcSuccessStreak: Int = 0
    var abcStruggleStreak: Int = 0
    var pressSuccessStreak: Int = 0
    var pressStruggleStreak: Int = 0
    var abcStreakKey: String = ""
    var pressStreakKey: String = ""
    var streakTargetRaw: String = ""
    var evaluatedSessionIDsData: Data = Data("[]".utf8)
    var lastDecision: String = "Finish a planned workout to begin."
    var decisionHistoryData: Data = Data("[]".utf8)
    var rescheduleHistoryData: Data = Data("[]".utf8)
    var pendingBellApproval: Bool = false
    var pendingBellTargetRaw: String = ""
    var modifiedAt: Date = Date()

    init() {}

    var weekdays: [Int] {
        get { (try? JSONDecoder().decode([Int].self, from: weekdaysData)) ?? [2, 4, 6] }
        set { weekdaysData = (try? JSONEncoder().encode(Array(Set(newValue.filter { (1...7).contains($0) })).sorted())) ?? Data("[2,4,6]".utf8); modifiedAt = Date() }
    }
    var templateDefinitions: [WorkoutDefinition] {
        get { (try? JSONDecoder().decode([WorkoutDefinition].self, from: templateDefinitionsData)) ?? [] }
        set { templateDefinitionsData = (try? JSONEncoder().encode(newValue)) ?? Data("[]".utf8); modifiedAt = Date() }
    }
    var nextOverride: WorkoutDefinition? {
        get { nextOverrideData.flatMap { try? JSONDecoder().decode(WorkoutDefinition.self, from: $0) } }
        set { nextOverrideData = newValue.flatMap { try? JSONEncoder().encode($0) }; modifiedAt = Date() }
    }
    var evaluatedSessionIDs: [UUID] {
        get { (try? JSONDecoder().decode([UUID].self, from: evaluatedSessionIDsData)) ?? [] }
        set { evaluatedSessionIDsData = (try? JSONEncoder().encode(newValue)) ?? Data("[]".utf8); modifiedAt = Date() }
    }
    var decisionHistory: [ProgramDecision] {
        get { (try? JSONDecoder().decode([ProgramDecision].self, from: decisionHistoryData)) ?? [] }
        set { decisionHistoryData = (try? JSONEncoder().encode(newValue)) ?? Data("[]".utf8); modifiedAt = Date() }
    }
    var rescheduleHistory: [ProgramReschedule] {
        get { (try? JSONDecoder().decode([ProgramReschedule].self, from: rescheduleHistoryData)) ?? [] }
        set { rescheduleHistoryData = (try? JSONEncoder().encode(newValue)) ?? Data("[]".utf8); modifiedAt = Date() }
    }
    var abcMode: WorkoutMode {
        get { WorkoutMode(rawValue: abcModeRaw) ?? .emom }
        set { abcModeRaw = newValue.rawValue; modifiedAt = Date() }
    }
}
