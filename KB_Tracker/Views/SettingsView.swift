import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("kb_pref_sound") private var sound = true
    @AppStorage("kb_pref_haptics") private var haptics = true
    @AppStorage("kb_pref_spoken") private var spoken = false
    @AppStorage("kb_pref_getReady") private var getReady = 5
    @AppStorage("kb_weight_unit") private var unit: WeightUnit = .kg
    @AppStorage("kb_health_auto") private var autoHealth = false
    @AppStorage("kb_cloud_enabled") private var cloud = false
    @State private var message: String?
    @State private var checkingCloud = false

    var body: some View {
        Form {
            Section("Equipment") {
                Picker("Display weight", selection: $unit) {
                    Text("Kilograms").tag(WeightUnit.kg)
                    Text("Pounds").tag(WeightUnit.lb)
                }
                NavigationLink("My kettlebells") { EquipmentView() }
                Text("Weight is stored without rounding. Changing units does not change your workout loads.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Workout cues") {
                Toggle("Beeps", isOn: $sound)
                Toggle("Haptics", isOn: $haptics)
                Toggle("Spoken cues", isOn: $spoken)
                Picker("Get-ready countdown", selection: $getReady) {
                    ForEach(WorkoutParameters.getReadyOptions, id: \.self) { Text("\($0) seconds").tag($0) }
                }
                Button("Enable lock-screen notifications") {
                    Task {
                        do { message = try await NotificationService.requestAuthorization() ? "Notifications enabled." : "Enable notifications for KB Tracker in system Settings." }
                        catch { message = error.localizedDescription }
                    }
                }
                Text("Spoken cues play while the app is open. Notifications can announce the next deadline when the phone is locked.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Apple Health") {
                Toggle("Export saved workouts automatically", isOn: Binding(get: { autoHealth }, set: { enabled in
                    if !enabled { autoHealth = false; return }
                    Task {
                        if await HealthKitService.requestAuthorization() { autoHealth = true }
                        else { message = "Allow workout access for KB Tracker in Apple Health, then try again." }
                    }
                }))
                Text("You can also export or retry a workout from its history page. Deleting a session here leaves any copy in Apple Health.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("iCloud") {
                Toggle("Sync saved workouts and plans", isOn: Binding(get: { cloud }, set: { enabled in
                    if !enabled { cloud = false; message = "Cloud sync will turn off when you reopen KB Tracker. Local history is retained."; return }
                    checkingCloud = true
                    Task {
                        defer { checkingCloud = false }
                        do {
                            try await PersistenceController.verifyCloudAccount()
                            cloud = true
                            message = "Cloud sync will turn on when you reopen KB Tracker."
                        } catch { message = error.localizedDescription }
                    }
                })).disabled(checkingCloud)
                if checkingCloud { ProgressView("Checking iCloud") }
                Text("Changes take effect at the next launch. Active workouts stay on this device. Synchronization requires the same Apple Account on your devices.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Backup") {
                NavigationLink("Export or import history") { HistoryView() }
                Text("Use JSON for a complete backup of sessions, workouts, equipment, and programs. CSV is available for analysis.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle("Settings")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        .alert("Settings", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK") { message = nil }
        } message: { Text(message ?? "") }
    }
}
