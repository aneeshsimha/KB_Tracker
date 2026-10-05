import SwiftData
import Foundation
import CloudKit

@MainActor enum PersistenceController {
    static let cloudContainer = "iCloud.aniche-studios.KB-Tracker"
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([WorkoutSession.self, WorkoutTemplate.self, EquipmentRecord.self, TrainingProgram.self])
        // Preserve the pre-existing store location after adding an App Group.
        let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let configuration = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("default.store"), cloudKitDatabase: UserDefaults.standard.bool(forKey: "kb_cloud_enabled") ? .private(cloudContainer) : .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
    static func verifyCloudAccount() async throws {
        let status = try await CKContainer(identifier: cloudContainer).accountStatus()
        guard status == .available else { throw CloudError.unavailable }
    }
    enum CloudError: LocalizedError {
        case unavailable
        var errorDescription: String? { "Sign in to iCloud in Settings to enable synchronization." }
    }
}
