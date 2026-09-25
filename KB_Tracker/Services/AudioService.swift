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

    private var soundEnabled: Bool {
        // Default true if key not set
        UserDefaults.standard.object(forKey: "kb_pref_sound") as? Bool ?? true
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

    // System sound IDs - using built-in iOS sounds

    /// Play countdown warning beep (softer, shorter)
    func playCountdownBeep() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1104)  // Soft tick
    }

    /// Play GO beep (louder, more prominent)
    func playGoBeep() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1103)  // Metallic ping
    }

    /// Play completion sound (workout finished)
    func playCompletionSound() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1025)  // Completion sound
    }
}
