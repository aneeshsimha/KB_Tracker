# Design/ Folder Plan

## Purpose
Contains design system definitions - colors, typography, and constants.

## Current State
| File | Description |
|------|-------------|
| `Colors.swift` | AppColors struct with color definitions |
| `Typography.swift` | AppTypography struct with font definitions |

## Target Files
| File | Status | Description |
|------|--------|-------------|
| `AppColors.swift` | Rename | Color definitions (rename from Colors.swift) |
| `AppTypography.swift` | Rename | Font definitions (rename from Typography.swift) |
| `AppConstants.swift` | Create | Timing values, weight ranges, defaults |

## Tasks

### 1. Rename Colors.swift → AppColors.swift
- [ ] Rename file
- [ ] No code changes needed (struct already named AppColors)

### 2. Rename Typography.swift → AppTypography.swift
- [ ] Rename file
- [ ] No code changes needed (struct already named AppTypography)

### 3. Create AppConstants.swift
- [ ] Extract magic numbers from views
- [ ] Timer constants (countdown duration, tick interval)
- [ ] Weight range constants
- [ ] Round/minute options

## Implementation Notes

### AppConstants.swift
```swift
// AppConstants.swift

import Foundation

struct AppConstants {
    // MARK: - Timer

    struct Timer {
        static let getReadyDuration: Int = 5
        static let tickInterval: TimeInterval = 0.1
        static let emomMinuteDuration: TimeInterval = 60
        static let countdownWarningStart: Int = 5
    }

    // MARK: - Weight

    struct Weight {
        static let minimum: Int = 12
        static let maximum: Int = 24
        static let step: Int = 2
        static let options: [Int] = Array(stride(from: minimum, through: maximum, by: step))
        static let defaultWeight: Int = 20
    }

    // MARK: - Rounds

    struct Rounds {
        static let options: [Int] = [5, 8, 10, 12, 15, 18, 20, 25, 30]
        static let defaultTarget: Int = 15
    }

    // MARK: - EMOM

    struct EMOM {
        static let minuteOptions: [Int] = [10, 12, 15, 18, 20, 22, 25, 30]
        static let defaultMinutes: Int = 20
    }

    // MARK: - Rest

    struct Rest {
        static let options: [Int] = [30, 45, 60, 90, 120]
        static let defaultSeconds: Int = 60
    }

    // MARK: - Animation

    struct Animation {
        static let defaultDuration: TimeInterval = 0.3
        static let quickDuration: TimeInterval = 0.15
    }
}
```

## Dependencies
- None (this is the design system foundation)

## Testing
- All views should compile after renames
- Constants should be accessible throughout the app
