# Services/ Folder Plan

## Purpose
Contains service layer classes for audio, haptics, and data persistence.

## Current State
- `Utilities/AudioManager.swift` - Sound playback (needs rename/move)
- No persistence service (SwiftData used directly in views)
- No haptics service

## Target Files
| File | Status | Description |
|------|--------|-------------|
| `AudioService.swift` | Move/Rename | Beeps, countdown sounds |
| `PersistenceService.swift` | Create | SwiftData container + CRUD |
| `HapticsService.swift` | Create | Vibration feedback |

## Tasks

### 1. Move/Rename AudioManager → AudioService
- [ ] Move from `Utilities/AudioManager.swift` → `Services/AudioService.swift`
- [ ] Rename class `AudioManager` → `AudioService`
- [ ] Update all references (EMOMTimerView, RoundsTimerView)
- [ ] Delete Utilities folder after move

### 2. Create PersistenceService.swift
- [ ] Centralize SwiftData operations
- [ ] CRUD methods for WorkoutSession
- [ ] Could be used for future caching/sync

### 3. Create HapticsService.swift
- [ ] Haptic feedback for button taps
- [ ] Haptic feedback for phase transitions
- [ ] Configurable haptic intensity

## Implementation Notes

### AudioService.swift (renamed from AudioManager)
```swift
// AudioService.swift

import AVFoundation
import AudioToolbox

class AudioService {
    static let shared = AudioService()

    private init() { configureAudioSession() }

    func playCountdownBeep() { ... }
    func playGoBeep() { ... }
    func playCompletionSound() { ... }
}
```

### PersistenceService.swift
```swift
// PersistenceService.swift

import Foundation
import SwiftData

class PersistenceService {
    static let shared = PersistenceService()

    // Could hold container reference, provide helper methods
    func saveSession(_ session: WorkoutSession, context: ModelContext) {
        context.insert(session)
        try? context.save()
    }

    func deleteSession(_ session: WorkoutSession, context: ModelContext) {
        context.delete(session)
        try? context.save()
    }
}
```

### HapticsService.swift
```swift
// HapticsService.swift

import UIKit

class HapticsService {
    static let shared = HapticsService()

    private init() {}

    func playLight() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func playMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func playHeavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func playWarning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}
```

## Dependencies
- Models/Enums.swift (for SystemSound enum, could move to AudioService)
- AVFoundation, AudioToolbox, UIKit frameworks

## Testing
- Audio plays correctly in silent mode
- Haptics fire on supported devices
- Persistence operations complete without errors
