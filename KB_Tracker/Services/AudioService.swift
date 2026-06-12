// AudioService.swift
// KB_Tracker
//
// Sound playback for timer beeps and cues

import AVFoundation
import AudioToolbox

protocol AudioCueing {
    func playCountdownBeep()
    func playGoBeep()
    func playCompletionSound()
}

class AudioService: AudioCueing {
    static let shared = AudioService()

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        #if os(iOS)
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
        #endif
    }

    /// Play countdown warning beep (softer, shorter)
    func playCountdownBeep() {
        playSystemSound(.tock)
    }

    /// Play GO beep (louder, more prominent)
    func playGoBeep() {
        playSystemSound(.tink)
    }

    /// Play completion sound (workout finished)
    func playCompletionSound() {
        playSystemSound(.fanfare)
    }

    private func playSystemSound(_ sound: SystemSound) {
        AudioServicesPlaySystemSound(sound.rawValue)
    }
}

// System sound IDs - using built-in iOS sounds
enum SystemSound: SystemSoundID {
    case tock = 1104      // Soft tick
    case tink = 1103      // Metallic ping
    case fanfare = 1025   // Completion sound
}
