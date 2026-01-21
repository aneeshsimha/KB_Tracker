// Date+Formatting.swift
// KB_Tracker
//
// Time formatting extensions

import Foundation

extension TimeInterval {
    /// Format as mm:ss (e.g., "5:23")
    var formattedTime: String {
        let mins = Int(self) / 60
        let secs = Int(self) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    /// Format as mm:ss with leading zero for minutes (e.g., "05:23")
    var formattedTimeWithLeadingZero: String {
        let mins = Int(self) / 60
        let secs = Int(self) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    /// Format for set time display - shows seconds only if under a minute
    var formattedSetTime: String {
        if self >= 60 {
            let mins = Int(self) / 60
            let secs = Int(self) % 60
            return String(format: "%d:%02d", mins, secs)
        } else {
            return "\(Int(self))s"
        }
    }
}
