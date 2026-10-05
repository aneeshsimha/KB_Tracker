import Foundation
import SwiftData
import Testing
@testable import KB_Tracker

@MainActor struct SessionRepositoryTests {
    @Test func recoveredSummarySavesOnlyOnce() throws {
        let schema = Schema([WorkoutSession.self, WorkoutTemplate.self, EquipmentRecord.self, TrainingProgram.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)])
        let context = ModelContext(container)
        let id = UUID()
        let original = WorkoutSession()
        original.id = id
        original.isCompleted = false
        original.notes = "Partial, recovered"
        try SessionRepository.save(original, context: context)
        let duplicate = WorkoutSession()
        duplicate.id = id
        duplicate.isCompleted = true
        try SessionRepository.save(duplicate, context: context)
        let saved = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(saved.count == 1)
        #expect(saved.first?.isCompleted == false)
        #expect(saved.first?.notes == "Partial, recovered")
    }
}
