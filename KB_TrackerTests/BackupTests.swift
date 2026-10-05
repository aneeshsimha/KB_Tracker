import Testing
import Foundation
@testable import KB_Tracker

struct BackupTests {
    @Test func archiveRoundTripsCodableSessionData() throws {
        let session = WorkoutSession()
        session.notes = "quoted, note"
        let archive = BackupService.Archive(sessions: [.init(session)])
        let decoded = try JSONDecoder().decode(BackupService.Archive.self, from: JSONEncoder().encode(archive))
        #expect(decoded.version == BackupService.currentVersion)
        #expect(decoded.sessions.first?.notes == "quoted, note")
    }
}
