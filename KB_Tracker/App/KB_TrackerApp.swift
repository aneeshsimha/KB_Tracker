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
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: WorkoutSession.self)
    }
}
