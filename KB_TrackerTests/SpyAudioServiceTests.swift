import Testing
import Foundation
@testable import KB_Tracker

// Spy that records cue names in order
final class SpyAudioService: AudioCueing {
    var cues: [String] = []
    func playCountdownBeep() { cues.append("countdown") }
    func playGoBeep() { cues.append("go") }
    func playCompletionSound() { cues.append("completion") }
}

@MainActor
struct SpyAudioServiceTests {
    @Test func recordsCuesInOrder() {
        let spy = SpyAudioService()
        spy.playGoBeep()
        spy.playCountdownBeep()
        spy.playCompletionSound()
        #expect(spy.cues == ["go", "countdown", "completion"])
    }

    @Test func emomTimerViewModelAcceptsInjectedAudio() {
        let spy = SpyAudioService()
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 20)
        let _ = EMOMTimerViewModel(config: config, audio: spy)
        // Just verifies the init compiles and doesn't crash — deeper behavior tested in characterization suite
        #expect(spy.cues.isEmpty)
    }
}
