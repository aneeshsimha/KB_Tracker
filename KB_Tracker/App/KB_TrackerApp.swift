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
    init() { storage = Result { try PersistenceController.makeContainer() } }
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
