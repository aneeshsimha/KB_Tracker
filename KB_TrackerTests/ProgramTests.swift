import XCTest
@testable import KB_Tracker

final class ProgramTests: XCTestCase {
    private func session(_ program: TrainingProgram, type: WorkoutType, difficulty: SessionDifficulty?, completed: Bool = true) -> WorkoutSession {
        let result = WorkoutSession()
        result.programID = program.id
        result.workoutType = type
        result.definition = type == .press ? .builtIn(.press(kettlebellType: .single, weight: 16, targetLadders: 3)) : .builtIn(.emom(kettlebellType: .double, weight: 16, minutes: 10))
        result.endedAt = Date()
        result.isCompleted = completed
        result.difficulty = difficulty
        return result
    }

    func testAlternatingTargetsProgressIndependentlyAndEvaluationIsIdempotent() {
        let program = TrainingProgram()
        let firstABC = session(program, type: .abc, difficulty: .manageable)
        ProgramService.evaluate(session: firstABC, program: program)
        XCTAssertEqual(program.nextIndex, 1)
        ProgramService.evaluate(session: session(program, type: .press, difficulty: .easy), program: program)
        ProgramService.evaluate(session: session(program, type: .abc, difficulty: .easy), program: program)
        XCTAssertEqual(program.abcMinutes, 11)
        XCTAssertEqual(program.pressLadders, 3)
        let count = program.nextIndex
        ProgramService.evaluate(session: firstABC, program: program)
        XCTAssertEqual(program.nextIndex, count)
        XCTAssertEqual(program.abcMinutes, 11)
    }

    func testHardAndIncompleteSessionsReduceTargetWithFloor() {
        let program = TrainingProgram()
        program.pressLadders = 5
        ProgramService.evaluate(session: session(program, type: .press, difficulty: .hard), program: program)
        ProgramService.evaluate(session: session(program, type: .press, difficulty: nil, completed: false), program: program)
        XCTAssertEqual(program.pressLadders, 4)
        program.pressLadders = 1
        ProgramService.evaluate(session: session(program, type: .press, difficulty: .hard), program: program)
        ProgramService.evaluate(session: session(program, type: .press, difficulty: .hard), program: program)
        XCTAssertEqual(program.pressLadders, 1)
    }

    func testMissingRatingHoldsAndCapRequiresApprovedBell() {
        let program = TrainingProgram()
        program.abcMinutes = 30
        program.abcStartMinutes = 12
        ProgramService.evaluate(session: session(program, type: .abc, difficulty: nil), program: program)
        XCTAssertEqual(program.abcMinutes, 30)
        ProgramService.evaluate(session: session(program, type: .abc, difficulty: .easy), program: program)
        ProgramService.evaluate(session: session(program, type: .abc, difficulty: .easy), program: program)
        XCTAssertTrue(program.pendingBellApproval)
        XCTAssertEqual(program.abcMinutes, 30)
        ProgramService.approveNextBell(program: program, weightKg: 16)
        XCTAssertTrue(program.pendingBellApproval)
        ProgramService.approveNextBell(program: program, weightKg: 20)
        XCTAssertEqual(program.abcMinutes, 12)
        XCTAssertEqual(program.abcWeightKg, 20)
        XCTAssertFalse(program.pendingBellApproval)
        XCTAssertEqual(program.decisionHistory.count, 4)
    }

    func testTemplateSequenceDoesNotProgress() {
        let program = TrainingProgram()
        let abc = WorkoutDefinition.builtIn(.emom(kettlebellType: .double, weight: 16, minutes: 8))
        let press = WorkoutDefinition.builtIn(.press(kettlebellType: .single, weight: 12, targetLadders: 2))
        program.usesTemplates = true
        program.templateDefinitions = [abc, press]
        XCTAssertEqual(ProgramService.nextDefinition(program: program).id, abc.id)
        ProgramService.evaluate(session: session(program, type: .abc, difficulty: .easy), program: program)
        XCTAssertEqual(ProgramService.nextDefinition(program: program).id, press.id)
        XCTAssertEqual(program.abcMinutes, 10)
    }

    func testExplicitBuiltInChoiceIgnoresCurrentOverride() {
        let program = TrainingProgram()
        program.nextOverride = ProgramService.builtInDefinition(program: program, type: .press)
        XCTAssertEqual(ProgramService.nextDefinition(program: program).workoutType, .press)
        XCTAssertEqual(ProgramService.builtInDefinition(program: program, type: .abc).workoutType, .abc)
        XCTAssertEqual(program.nextIndex, 0)
    }

    func testPrescriptionComparisonNormalizesMovementNames() {
        var first = WorkoutDefinition.builtIn(.emom(kettlebellType: .double, weight: 16, minutes: 10))
        var second = first
        second.blocks[0].movements[0].name = "  CLEAN  "
        XCTAssertEqual(ProgramService.prescriptionKey(first), ProgramService.prescriptionKey(second))
        first.blocks[0].movements[0].reps = 3
        XCTAssertNotEqual(ProgramService.prescriptionKey(first), ProgramService.prescriptionKey(second))
    }

    func testRescheduleHistoryPersistsAfterActiveOverrideClears() {
        let program = TrainingProgram()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let sunday = calendar.date(from: DateComponents(year: 2026, month: 10, day: 4))!
        let original = calendar.date(byAdding: .day, value: 1, to: sunday)!
        let moved = calendar.date(byAdding: .day, value: 2, to: sunday)!
        program.rescheduleHistory = [ProgramReschedule(plannedDate: original, movedDate: moved)]
        program.rescheduledDate = moved
        program.rescheduledDate = nil
        XCTAssertEqual(program.rescheduleHistory.first?.movedDate, moved)
        let dates = ProgramService.plannedDates(program: program, inWeekStarting: sunday, calendar: calendar)
        XCTAssertEqual(dates.count, 3)
        XCTAssertTrue(dates.contains(moved))
        XCTAssertFalse(dates.contains(original))
    }
}
