import Testing
import Foundation
@testable import KB_Tracker

@MainActor
struct PressLadderViewModelTests {
    private func makeVM(ladders: Int = 2) -> PressLadderViewModel {
        PressLadderViewModel(config: .press(kettlebellType: .single, weight: 16, targetLadders: ladders))
    }

    @Test func startsAtLadderOneRungTwo() {
        let vm = makeVM()
        #expect(vm.currentLadder == 1)
        #expect(vm.currentRungReps == 2)
        #expect(vm.totalReps == 0)
        #expect(vm.isComplete == false)
    }

    @Test func logRungAdvancesThroughRungs() {
        let vm = makeVM()
        vm.logRung()                       // logged 2 → rung 3
        #expect(vm.currentRungReps == 3)
        #expect(vm.totalReps == 2)
        vm.logRung(); vm.logRung()         // 3, then 5 → rung 10
        #expect(vm.currentRungReps == 10)
        #expect(vm.totalReps == 10)
    }

    @Test func completingLadderAdvancesToNext() {
        let vm = makeVM(ladders: 2)
        for _ in 0..<4 { vm.logRung() }    // full ladder (2+3+5+10)
        #expect(vm.currentLadder == 2)
        #expect(vm.currentRungReps == 2)
        #expect(vm.totalReps == 20)
        #expect(vm.isComplete == false)
    }

    @Test func finishesAtTargetLadders() {
        let vm = makeVM(ladders: 1)
        for _ in 0..<4 { vm.logRung() }
        #expect(vm.isComplete)
        #expect(vm.completedSession?.workoutType == .press)
        #expect(vm.completedSession?.totalReps == 20)
        #expect(vm.completedSession?.completedLadders == 1)
        #expect(vm.completedSession?.isCompleted == true)
    }

    @Test func undoStepsBackWithinLadder() {
        let vm = makeVM()
        vm.logRung()                       // total 2, rung 3
        vm.undoLastRung()
        #expect(vm.currentRungReps == 2)
        #expect(vm.totalReps == 0)
    }

    @Test func undoStepsBackAcrossLadderBoundary() {
        let vm = makeVM(ladders: 3)
        for _ in 0..<4 { vm.logRung() }    // completed ladder 1, now ladder 2 rung 2
        vm.undoLastRung()                  // back into ladder 1's rung 10
        #expect(vm.currentLadder == 1)
        #expect(vm.currentRungReps == 10)
        #expect(vm.totalReps == 10)        // 2+3+5 logged in the reopened ladder
    }

    @Test func endEarlySavesPartial() {
        let vm = makeVM(ladders: 5)
        vm.logRung(); vm.logRung()         // 2 + 3 = 5 reps into ladder 1
        vm.endEarly()
        #expect(vm.partialSession?.isCompleted == false)
        #expect(vm.partialSession?.totalReps == 5)
        #expect(vm.partialSession?.completedLadders == 0)
        #expect(vm.session?.totalReps == 5)
    }
}
