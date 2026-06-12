// Date+Formatting.swift
// KB_Tracker
//
// Extensions for formatting dates and time intervals

import Foundation

// MARK: - TimeInterval Formatting

extension TimeInterval {
    /// Format as mm:ss (e.g., "1:30", "12:05")
    var formattedMinutesSeconds: String {
        let mins = Int(self) / 60
        let secs = Int(self) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    /// Format as mm:ss with leading zero on minutes (e.g., "01:30", "12:05")
    var formattedMinutesSecondsPadded: String {
        let mins = Int(self) / 60
        let secs = Int(self) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    /// Format as seconds only if under 60, otherwise mm:ss (e.g., "45s" or "1:30")
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

// MARK: - Int Formatting

extension Int {
    /// Format as mm:ss with leading zero on minutes, clamping negative values to zero.
    var formattedMinutesSecondsPadded: String {
        let clamped = self < 0 ? 0 : self
        return TimeInterval(clamped).formattedMinutesSecondsPadded
    }
}
