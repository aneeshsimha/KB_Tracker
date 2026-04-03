//
//  KB_TrackerTests.swift
//  KB_TrackerTests
//
//  Unit tests for timer, rounds, and history logic
//

import Testing
@testable import KB_Tracker

// MARK: - WorkoutConfig Tests

struct WorkoutConfigTests {

    @Test func emomFactoryMethod() {
        let config = WorkoutConfig.emom(kettlebellType: .double, weight: 20, minutes: 15)
        #expect(config.mode == .emom)
        #expect(config.kettlebellType == .double)
        #expect(config.weight == 20)
        #expect(config.targetRounds == 15)
        #expect(config.restDuration == nil)
    }

    @Test func roundsFactoryMethod() {
        let config = WorkoutConfig.rounds(kettlebellType: .single, weight: 16, rounds: 10, restSeconds: 90)
        #expect(config.mode == .rounds)
        #expect(config.kettlebellType == .single)
        #expect(config.weight == 16)
        #expect(config.targetRounds == 10)
        #expect(config.restDuration == 90)
    }

    @Test func weightDisplayDouble() {
        let config = WorkoutConfig.emom(kettlebellType: .double, weight: 20, minutes: 10)
        #expect(config.weightDisplay == "2×20kg")
    }

    @Test func weightDisplaySingle() {
        let config = WorkoutConfig.emom(kettlebellType: .single, weight: 16, minutes: 10)
        #expect(config.weightDisplay == "16kg")
    }
}

// MARK: - WorkoutSession Tests

struct WorkoutSessionTests {

    @Test func convenienceInit() {
        let session = WorkoutSession(mode: .emom, kettlebellType: .double, weight: 20, targetRounds: 15)
        #expect(session.mode == .emom)
        #expect(session.kettlebellType == .double)
        #expect(session.weight == 20)
        #expect(session.targetRounds == 15)
        #expect(session.completedRounds == 0)
        #expect(session.totalDuration == 0)
        #expect(session.setTimes.isEmpty)
        #expect(session.notes == nil)
        #expect(session.isCompleted == false)
    }

    @Test func weightDisplayDouble() {
        let session = WorkoutSession(mode: .emom, kettlebellType: .double, weight: 20, targetRounds: 10)
        #expect(session.weightDisplay == "2×20kg")
    }

    @Test func weightDisplaySingle() {
        let session = WorkoutSession(mode: .emom, kettlebellType: .single, weight: 16, targetRounds: 10)
        #expect(session.weightDisplay == "16kg")
    }

    @Test func averageSetTimeEmpty() {
        let session = WorkoutSession(mode: .emom, kettlebellType: .double, weight: 20, targetRounds: 10)
        #expect(session.averageSetTime == nil)
    }

    @Test func averageSetTimeCalculation() {
        let session = WorkoutSession(mode: .emom, kettlebellType: .double, weight: 20, targetRounds: 10)
        session.setTimes = [30.0, 40.0, 50.0]
        #expect(session.averageSetTime == 40.0)
    }

    @Test func hasOvertimeSetsEMOMTrue() {
        let session = WorkoutSession(mode: .emom, kettlebellType: .double, weight: 20, targetRounds: 10)
        session.setTimes = [45.0, 65.0, 50.0]
        #expect(session.hasOvertimeSets == true)
    }

    @Test func hasOvertimeSetsEMOMFalse() {
        let session = WorkoutSession(mode: .emom, kettlebellType: .double, weight: 20, targetRounds: 10)
        session.setTimes = [45.0, 55.0, 50.0]
        #expect(session.hasOvertimeSets == false)
    }

    @Test func hasOvertimeSetsRoundsAlwaysFalse() {
        let session = WorkoutSession(mode: .rounds, kettlebellType: .double, weight: 20, targetRounds: 10, restDuration: 60)
        session.setTimes = [45.0, 65.0, 50.0]
        #expect(session.hasOvertimeSets == false)
    }

    @Test func roundsDisplay() {
        let session = WorkoutSession(mode: .emom, kettlebellType: .double, weight: 20, targetRounds: 20)
        session.completedRounds = 18
        #expect(session.roundsDisplay == "18/20")
    }
}

// MARK: - TimerViewModel Tests

struct TimerViewModelTests {

    @Test @MainActor func emomInitialState() async {
        let vm = TimerViewModel(config: .emom(kettlebellType: .double, weight: 20, minutes: 15))
        #expect(vm.currentRound == 0)
        #expect(vm.totalElapsed == 0)
        #expect(vm.setTimes.isEmpty)
        #expect(vm.isSetInProgress == false)
        #expect(vm.emomPhase == .getReady)
        #expect(vm.isComplete == false)
        #expect(vm.getReadyCountdown == 5)
        #expect(vm.secondsIntoMinute == 0)
    }

    @Test @MainActor func roundsInitialState() async {
        let vm = TimerViewModel(config: .rounds(kettlebellType: .double, weight: 20, rounds: 10, restSeconds: 60))
        #expect(vm.currentRound == 0)
        #expect(vm.roundsPhase == .getReady)
        #expect(vm.restCountdown == 0)
        #expect(vm.currentSetElapsed == 0)
        #expect(vm.isComplete == false)
        #expect(vm.totalElapsed == 0)
        #expect(vm.setTimes.isEmpty)
    }

    @Test @MainActor func weightDisplayDelegation() async {
        let config = WorkoutConfig.emom(kettlebellType: .double, weight: 20, minutes: 10)
        let vm = TimerViewModel(config: config)
        #expect(vm.weightDisplay == config.weightDisplay)
        #expect(vm.weightDisplay == "2×20kg")
    }

    @Test @MainActor func countdownSecondsInitial() async {
        let vm = TimerViewModel(config: .emom(kettlebellType: .double, weight: 20, minutes: 10))
        // secondsIntoMinute is 0, so countdownSeconds = 60 - 0 = 60
        #expect(vm.countdownSeconds == 60)
        #expect(vm.isOvertime == false)
    }

    @Test @MainActor func emomSetDoneGuardWhenNotInProgress() async {
        let vm = TimerViewModel(config: .emom(kettlebellType: .double, weight: 20, minutes: 10))
        // isSetInProgress is false, so handleEMOMSetDone should be a no-op
        vm.handleEMOMSetDone()
        #expect(vm.setTimes.isEmpty)
        #expect(vm.isSetInProgress == false)
    }

    @Test @MainActor func roundsSetDoneGuardWhenNotWorking() async {
        let vm = TimerViewModel(config: .rounds(kettlebellType: .double, weight: 20, rounds: 10, restSeconds: 60))
        // roundsPhase is .getReady, so handleRoundsSetDone should be a no-op
        vm.handleRoundsSetDone()
        #expect(vm.setTimes.isEmpty)
        #expect(vm.roundsPhase == .getReady)
    }

    @Test @MainActor func savePartialWorkout() async {
        let vm = TimerViewModel(config: .emom(kettlebellType: .double, weight: 20, minutes: 15))
        vm.savePartialWorkout()

        #expect(vm.partialSession != nil)
        let session = vm.partialSession!
        #expect(session.isCompleted == false)
        #expect(session.mode == .emom)
        #expect(session.kettlebellType == .double)
        #expect(session.weight == 20)
        #expect(session.targetRounds == 15)
        // vm.session should fall back to partialSession when completedSession is nil
        #expect(vm.completedSession == nil)
        #expect(vm.session != nil)
    }
}
