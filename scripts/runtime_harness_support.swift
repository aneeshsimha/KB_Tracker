import Foundation

struct ProgramDecision: Codable, Hashable, Identifiable {
    var id = UUID(); var sessionID: UUID?; var date = Date(); var message: String
}
struct ProgramReschedule: Codable, Hashable, Identifiable {
    var id = UUID(); var plannedDate: Date; var movedDate: Date
}
final class TrainingProgram {
    var id = UUID(); var weekdays = [2, 4, 6]; var autoProgress = true; var usesTemplates = false
    var templateDefinitions: [WorkoutDefinition] = []; var nextIndex = 0
    var nextOverride: WorkoutDefinition?; var rescheduledDate: Date?
    var rescheduleHistory: [ProgramReschedule] = []
    var abcMode: WorkoutMode = .emom; var abcMinutes = 10; var abcRounds = 10
    var abcStartMinutes = 10; var abcStartRounds = 10; var abcRestSeconds = 60
    var abcWeightKg = 16.0; var abcBells = 2; var pressLadders = 3; var pressStartLadders = 3
    var pressWeightKg = 16.0; var pressBells = 1
    var abcSuccessStreak = 0; var abcStruggleStreak = 0
    var pressSuccessStreak = 0; var pressStruggleStreak = 0
    var abcStreakKey = ""; var pressStreakKey = ""; var streakTargetRaw = ""
    var evaluatedSessionIDs: [UUID] = []; var lastDecision = ""
    var decisionHistory: [ProgramDecision] = []; var pendingBellApproval = false
    var pendingBellTargetRaw = ""; var modifiedAt = Date()
}

// SwiftData's macro implementation is not shipped in standalone Command Line Tools.
// This persistence-free session has the same surface consumed by WorkoutRuntime; the
// runtime and all workout value models remain the production sources under test.
final class WorkoutSession {
    var id = UUID()
    var date = Date()
    var mode: WorkoutMode = .emom
    var kettlebellType: KBType = .double
    var weight = 20
    var targetRounds = 20
    var completedRounds = 0
    var totalDuration: TimeInterval = 0
    var restDuration: Int?
    var setTimes: [TimeInterval] = []
    var notes: String?
    var isCompleted = false
    var workoutType: WorkoutType = .abc
    var targetLadders = 0
    var ladderReps: [Int] = []
    var definition: WorkoutDefinition?
    var results: [WorkoutSetResult] = []
    var endedAt: Date?
    var pausedDuration: TimeInterval = 0
    var sourceRaw = "legacy"
    var difficulty: SessionDifficulty?
    var programID: UUID?

    init() {}
    init(mode: WorkoutMode, kettlebellType: KBType, weight: Int,
         targetRounds: Int, restDuration: Int? = nil) {
        self.mode = mode
        self.kettlebellType = kettlebellType
        self.weight = weight
        self.targetRounds = targetRounds
        self.restDuration = restDuration
    }
}

protocol AudioCueing {
    func playCountdownBeep()
    func playGoBeep()
    func playCompletionSound()
    func announce(_ phrase: String)
}

final class AudioService: AudioCueing {
    static let shared = AudioService()
    func playCountdownBeep() {}
    func playGoBeep() {}
    func playCompletionSound() {}
    func announce(_ phrase: String) {}
}

@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()
    func start(workoutType: String, totalTarget: Int, mode: String, getReadySeconds: Int) {}
    func update(phase: String, currentRound: Int, totalRounds: Int,
                elapsedSeconds: TimeInterval, mode: String, countdownEndDate: Date) {}
    func end(currentRound: Int, totalRounds: Int, elapsedSeconds: TimeInterval, mode: String) {}
}

@MainActor
enum NotificationService {
    static func scheduleWorkoutCue(at deadline: Date, title: String) async {}
    static func cancelWorkoutCue() {}
}
