import Testing
import Foundation
@testable import KB_Tracker

struct HomeSetupLogicTests {
    // No session — use onboarding prefs
    @Test func noSessionUsesSinglePref() {
        let result = HomeSetupLogic.initialKBSetup(lastSession: nil, prefKBType: "single", prefWeight: 24)
        #expect(result.kbType == .single)
        #expect(result.weight == 24)
    }

    @Test func noSessionUsesDoublePref() {
        let result = HomeSetupLogic.initialKBSetup(lastSession: nil, prefKBType: "double", prefWeight: 16)
        #expect(result.kbType == .double)
        #expect(result.weight == 16)
    }

    @Test func noSessionBadRawValueFallsBackToDouble() {
        let result = HomeSetupLogic.initialKBSetup(lastSession: nil, prefKBType: "invalid", prefWeight: 20)
        #expect(result.kbType == .double)
        #expect(result.weight == 20)
    }

    // Last session overrides prefs
    @Test func lastSessionOverridesPref() {
        let session = WorkoutSession()
        session.kettlebellType = .single
        session.weight = 20
        session.mode = .emom
        session.targetRounds = 15
        session.isCompleted = true
        let result = HomeSetupLogic.initialKBSetup(lastSession: session, prefKBType: "double", prefWeight: 24)
        #expect(result.kbType == .single)
        #expect(result.weight == 20)
    }
}
