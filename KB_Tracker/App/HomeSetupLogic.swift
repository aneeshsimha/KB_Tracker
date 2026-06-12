// HomeSetupLogic.swift
// KB_Tracker

import Foundation

enum HomeSetupLogic {
    struct KBSetup {
        let kbType: KBType
        let weight: Int
    }

    static func initialKBSetup(lastSession: WorkoutSession?, prefKBType: String, prefWeight: Int) -> KBSetup {
        if let session = lastSession {
            return KBSetup(kbType: session.kettlebellType, weight: session.weight)
        }
        let kbType = KBType(rawValue: prefKBType) ?? .double
        return KBSetup(kbType: kbType, weight: prefWeight)
    }
}
