import Foundation
import UserNotifications

@MainActor enum NotificationService {
    private static var workoutGeneration = 0
    private static var programGeneration = 0
    static func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }
    static func scheduleProgram(days: [Int], hour: Int, minute: Int, override: Date? = nil) async {
        clearProgram()
        let generation = programGeneration
        guard (try? await requestAuthorization()) == true else { return }
        guard generation == programGeneration else { return }
        let calendar = Calendar.current
        let now = Date()
        var dates: [Date] = []
        for offset in 0..<84 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now),
                  days.contains(calendar.component(.weekday, from: day)),
                  let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day), date > now else { continue }
            dates.append(date)
            if dates.count == 32 { break }
        }
        if let override, override > now {
            if !dates.isEmpty { dates.removeFirst() }
            dates.insert(override, at: 0)
        }
        for (index, date) in Array(Set(dates)).sorted().enumerated() {
            guard generation == programGeneration else { return }
            let content = UNMutableNotificationContent()
            content.title = "Your next workout"
            content.body = "Open KB Tracker to see your training plan."
            content.sound = .default
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let request = UNNotificationRequest(identifier: "kb-program-\(index)", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
    static func clearProgram() {
        programGeneration += 1
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: (0...32).map { "kb-program-\($0)" })
    }
    static func scheduleWorkoutCue(at deadline: Date, title: String) async {
        cancelWorkoutCue()
        let generation = workoutGeneration
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard generation == workoutGeneration else { return }
        guard settings.authorizationStatus == .authorized, deadline.timeIntervalSinceNow > 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Open your workout to continue logging."
        if UserDefaults.standard.object(forKey: "kb_pref_sound") as? Bool ?? true { content.sound = .default }
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "kb-active-workout", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: deadline.timeIntervalSinceNow, repeats: false)))
    }
    static func cancelWorkoutCue() {
        workoutGeneration += 1
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["kb-active-workout"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["kb-active-workout"])
    }
}
