# Utilities Directory

This directory contains helper classes and utilities used across the app.

---

## Files

### AudioManager.swift

**Purpose:** Handle all sound playback for timer cues (beeps, warnings, completion)

**Interface:**
```swift
class AudioManager {
    static let shared = AudioManager()

    func playCountdownBeep()      // 5-4-3-2-1 warning beeps
    func playGoBeep()             // Start of minute/set - louder
    func playCompletionSound()    // Workout finished (optional)
}
```

**Implementation:**

```swift
import AVFoundation

class AudioManager {
    static let shared = AudioManager()

    private var audioPlayer: AVAudioPlayer?

    private init() {
        // Configure audio session for playback
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            // Allow audio to play even in silent mode (important for workout apps)
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    /// Play countdown warning beep (softer, shorter)
    func playCountdownBeep() {
        playSystemSound(.tock)
    }

    /// Play GO beep (louder, more prominent)
    func playGoBeep() {
        playSystemSound(.tink)
    }

    /// Play completion sound (optional - workout finished)
    func playCompletionSound() {
        playSystemSound(.fanfare)
    }

    private func playSystemSound(_ sound: SystemSound) {
        AudioServicesPlaySystemSound(sound.rawValue)
    }
}

// System sound IDs - using built-in iOS sounds
// Alternative: Bundle custom .wav/.mp3 files
enum SystemSound: SystemSoundID {
    case tock = 1104      // Soft tick
    case tink = 1103      // Metallic ping
    case fanfare = 1025   // Completion sound
}
```

**Alternative: Custom Sound Files**

If system sounds aren't sufficient, bundle custom audio:

```swift
func playSound(named name: String) {
    guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
        print("Sound file not found: \(name)")
        return
    }

    do {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    } catch {
        print("Failed to play sound: \(error)")
    }
}
```

**Sound Files to Create (if using custom):**
- `countdown_beep.wav` - Short, soft tick
- `go_beep.wav` - Louder, sharper beep
- `complete.wav` - Positive completion sound

---

## Audio Session Notes

**Important for workout apps:**

1. **Silent Mode:** By default, iOS respects the silent switch. For workout apps, you usually want sound even when silent. Use `.playback` category.

2. **Background Audio:** If the app goes to background during workout, audio may stop. For MVP, this is acceptable. For polish, add background mode capability.

3. **Interruptions:** Handle audio interruptions (phone calls, etc.) gracefully. The timer should continue even if audio is interrupted.

```swift
// Optional: Handle interruptions
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleInterruption),
    name: AVAudioSession.interruptionNotification,
    object: nil
)

@objc private func handleInterruption(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
        return
    }

    switch type {
    case .began:
        // Audio was interrupted (e.g., phone call)
        break
    case .ended:
        // Interruption ended, resume if needed
        try? AVAudioSession.sharedInstance().setActive(true)
    @unknown default:
        break
    }
}
```

---

## Usage in Timer Views

```swift
// In EMOMTimerView

func handleTimerTick() {
    totalElapsed += 0.1

    // 5 second countdown warning
    if secondsIntoMinute >= 55 && secondsIntoMinute < 60 {
        let secondMark = Int(secondsIntoMinute)
        if secondMark != lastBeepSecond {
            AudioManager.shared.playCountdownBeep()
            lastBeepSecond = secondMark
        }
    }

    // Start of minute
    if secondsIntoMinute >= 60 {
        secondsIntoMinute = 0
        currentRound += 1
        AudioManager.shared.playGoBeep()
        setStartTime = Date()
    }
}
```

---

## Dependencies

- AVFoundation (Apple framework)
- AudioToolbox (for SystemSoundID)

---

## Used By

- EMOMTimerView
- RoundsTimerView
- SummaryView (completion sound, optional)

---

## Testing Notes

- Test with silent mode ON - sounds should still play
- Test with headphones connected
- Test audio interruption (simulate incoming call)
- Verify beeps are distinguishable (countdown vs go)
