//
//  KB_TrackerApp.swift
//  KB_Tracker
//
//  Created by Aneesh Simha on 1/15/26.
//

import SwiftUI
import SwiftData

@main
struct KB_TrackerApp: App {
    private let storage: Result<ModelContainer, Error>
    init() {
        storage = Result {
            #if DEBUG
            if ProcessInfo.processInfo.environment["KB_UI_TESTING"] == "1" {
                UserDefaults.standard.set(3, forKey: "kb_pref_getReady")
                UserDefaults.standard.set(false, forKey: "kb_health_auto")
                try ActiveWorkoutStore.clear()
                let schema = Schema([WorkoutSession.self, WorkoutTemplate.self, EquipmentRecord.self, TrainingProgram.self])
                let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)])
                let configs: [WorkoutConfig] = [
                    .emom(kettlebellType: .double, weight: 16, minutes: 1),
                    .press(kettlebellType: .single, weight: 16, targetLadders: 1),
                    .snatchTest(kettlebellType: .single, weight: 16, minutes: 1),
                    .swingInterval(kettlebellType: .single, weight: 16, rounds: 1, restSeconds: 0)
                ]
                for config in configs {
                    var definition = WorkoutDefinition.builtIn(config)
                    definition.name = "Test \(config.workoutType.title)"
                    definition.blocks[0].rungs = [1]
                    definition.blocks[0].restSeconds = 0
                    container.mainContext.insert(WorkoutTemplate(definition: definition, isFavorite: true))
                }
                let mixed = WorkoutDefinition(name: "Test mixed", blocks: [
                    WorkoutBlock(name: "Warmup", kind: .warmup, workSeconds: 1, restSeconds: 0),
                    WorkoutBlock(name: "Swings", kind: .rounds, movements: [.init(name: "Swing", reps: 5)], rounds: 1, restSeconds: 0)
                ])
                container.mainContext.insert(WorkoutTemplate(definition: mixed, isFavorite: true))
                try container.mainContext.save()
                return container
            }
            #endif
            return try PersistenceController.makeContainer()
        }
    }
    var body: some Scene {
        WindowGroup {
            switch storage {
            case .success(let container):
                RootView().modelContainer(container)
            case .failure(let error):
                ContentUnavailableView {
                    Label("Your history could not be opened", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text(error.localizedDescription + " Your stored data has not been deleted. Close and reopen the app to retry.")
                } actions: {
                    Button("Disable cloud sync for next launch") {
                        UserDefaults.standard.set(false, forKey: "kb_cloud_enabled")
                    }
                }
            }
        }
    }
}
