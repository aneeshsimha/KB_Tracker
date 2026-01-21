# Extensions/ Folder Plan

## Purpose
Contains Swift extensions for common functionality.

## Current State
- No Extensions folder exists
- Date formatting is duplicated across views (formatTime function)

## Target Files
| File | Status | Description |
|------|--------|-------------|
| `Date+Formatting.swift` | Create | Date and time formatting helpers |

## Tasks

### 1. Create Date+Formatting.swift
- [ ] Extract `formatTime(_ seconds: TimeInterval) -> String` from views
- [ ] Add other useful date formatters
- [ ] Remove duplicate implementations from views

## Implementation Notes

### Date+Formatting.swift
```swift
// Date+Formatting.swift

import Foundation

extension TimeInterval {
    /// Format as "M:SS" (e.g., "1:45")
    var timerDisplay: String {
        let mins = Int(self) / 60
        let secs = Int(self) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    /// Format as "MM:SS" with leading zero (e.g., "01:45")
    var timerDisplayPadded: String {
        let mins = Int(self) / 60
        let secs = Int(self) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    /// Format as seconds only (e.g., "45s")
    var secondsDisplay: String {
        "\(Int(self))s"
    }

    /// Format as short time, preferring seconds for <60 (e.g., "45s" or "1:30")
    var shortDisplay: String {
        if self >= 60 {
            return timerDisplay
        } else {
            return secondsDisplay
        }
    }
}

extension Date {
    /// Format for history list (e.g., "Jan 15, 2026")
    var historyDisplay: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    /// Format for detail view (e.g., "January 15, 2026 at 3:30 PM")
    var detailDisplay: String {
        formatted(date: .complete, time: .shortened)
    }
}
```

## Usage After Refactor

### Before (duplicated in every view)
```swift
private func formatTime(_ seconds: TimeInterval) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", mins, secs)
}

// Usage
Text(formatTime(totalElapsed))
```

### After (using extension)
```swift
// Usage
Text(totalElapsed.timerDisplay)
```

## Files to Update After Creating Extension
- EMOMTimerView.swift - remove formatTime function
- RoundsTimerView.swift - remove formatTime function
- SummaryView.swift - remove formatTime, formatSetTime functions
- HistoryDetailView.swift - remove formatTime function

## Dependencies
- Foundation

## Testing
- All time displays should look identical after refactor
- Different formatters should produce expected output
