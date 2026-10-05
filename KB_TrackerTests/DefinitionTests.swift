import XCTest
@testable import KB_Tracker

final class DefinitionTests: XCTestCase {
    func testMixedBlocksRoundTripAndValidation() throws {
        var warmup = WorkoutBlock(name: "Warmup", kind: .warmup)
        warmup.movements = [.init(name: "Halos", reps: 5, perSide: true)]
        var ladder = WorkoutBlock(name: "Press", kind: .ladder)
        ladder.movements = [.init(name: "Press", reps: nil, perSide: true)]
        ladder.rungs = [2, 3, 5]
        let definition = WorkoutDefinition(name: "Mixed", blocks: [warmup, ladder])
        XCTAssertNil(definition.validationError)
        let copy = try JSONDecoder().decode(WorkoutDefinition.self, from: JSONEncoder().encode(definition))
        XCTAssertEqual(copy, definition)
        XCTAssertEqual(copy.blocks[1].targetSets, ladder.rounds * 3)
    }

    func testInvalidLoadsAndRungsFail() {
        var block = WorkoutBlock(name: "Press", kind: .ladder)
        block.loadKg = 0
        XCTAssertNotNil(block.validationError)
        block.loadKg = 16
        block.rungs = []
        XCTAssertNotNil(block.validationError)
    }

    func testPoundsAreStoredAsKilograms() {
        let kilograms = WeightUnit.lb.kilograms(35)
        XCTAssertEqual(kilograms, 15.875233, accuracy: 0.000001)
        XCTAssertEqual(WeightUnit.lb.display(kilograms), 35, accuracy: 0.000001)
    }

    func testRungDraftRejectsIncompleteInputWithoutDroppingIt() {
        XCTAssertNil(WorkoutEditorView.parseRungs("2,"))
        XCTAssertNil(WorkoutEditorView.parseRungs("2, no"))
        XCTAssertEqual(WorkoutEditorView.parseRungs("2, 3, 5"), [2, 3, 5])
    }

    func testEditedBuiltinStructureBecomesCustom() {
        var abc = WorkoutDefinition.builtIn(.emom(kettlebellType: .double, weight: 16, minutes: 10))
        XCTAssertTrue(WorkoutEditorView.preservesBuiltinIdentity(abc))
        abc.blocks[0].movements[0].reps = 3
        XCTAssertFalse(WorkoutEditorView.preservesBuiltinIdentity(abc))
    }
}
