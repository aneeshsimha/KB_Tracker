# App/ Folder Plan

## Purpose
Contains the app entry point and app-level configuration.

## Current State
- `KB_TrackerApp.swift` exists in the root of KB_Tracker/

## Target Files
| File | Status | Description |
|------|--------|-------------|
| `KB_TrackerApp.swift` | Move | @main entry point, environment setup |
| `AppDelegate.swift` | Create | Background audio session, notifications (if needed) |

## Tasks

### 1. Move KB_TrackerApp.swift
- [ ] Move from `KB_Tracker/KB_TrackerApp.swift` → `KB_Tracker/App/KB_TrackerApp.swift`
- [ ] Update Xcode project file references

### 2. Create AppDelegate.swift (Optional)
- [ ] Create AppDelegate if background audio/notifications are needed
- [ ] Configure `UIApplicationDelegateAdaptor` in KB_TrackerApp
- [ ] Handle background audio session setup

## Implementation Notes
```swift
// AppDelegate.swift
import UIKit
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure background audio if needed
        return true
    }
}
```

## Dependencies
- None (this is the app root)

## Testing
- App should launch correctly after move
- Dark mode preference should be preserved
- SwiftData container should initialize correctly
