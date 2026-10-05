import Foundation
import SwiftData

enum BlockKind: String, Codable, CaseIterable, Identifiable {
    case warmup, emom, rounds, ladder, interval, cooldown
    var id: String { rawValue }
    var title: String {
        switch self {
        case .warmup: return "Warmup"
        case .emom: return "EMOM"
        case .rounds: return "Rounds"
        case .ladder: return "Ladder"
        case .interval: return "Work / rest"
        case .cooldown: return "Cooldown"
        }
    }
    var isTimed: Bool { self == .warmup || self == .cooldown || self == .interval }
}

struct WorkoutMovement: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var reps: Int? = nil
    /// A rep target is for each side when true; totals include both sides.
    var perSide = false
}

struct WorkoutBlock: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String = "Block"
    var kind: BlockKind = .rounds
    var movements: [WorkoutMovement] = [WorkoutMovement(name: "Swing", reps: 10)]
    var loadKg: Double = 16
    var bells: Int = 1
    var rounds: Int = 5
    var workSeconds: Int = 60
    var restSeconds: Int = 60
    var rungs: [Int] = [2, 3, 5, 10]

    var targetSets: Int { kind == .ladder ? rounds * rungs.count : (kind == .warmup || kind == .cooldown ? 1 : rounds) }
    var validationError: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Name every block." }
        if !loadKg.isFinite || loadKg <= 0 || loadKg > 500 { return "Enter a load between 0 and 500 kg." }
        if !(1...2).contains(bells) || !(1...500).contains(rounds) { return "Choose one or two bells and 1–500 rounds." }
        if !(1...86400).contains(workSeconds) || !(0...3600).contains(restSeconds) { return "Enter valid work and rest durations." }
        if movements.isEmpty || movements.contains(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || ($0.reps != nil && !(1...10000).contains($0.reps!)) }) { return "Name each movement and enter positive rep targets, or leave reps unknown." }
        if kind == .ladder && (movements.count != 1 || rungs.isEmpty || rungs.count > 20 || rungs.contains(where: { !(1...1000).contains($0) })) { return "A ladder needs one movement and 1–20 positive rungs." }
        return nil
    }
}

struct WorkoutDefinition: Codable, Hashable, Identifiable {
    var id = UUID()
    var version = 1
    var name: String
    var workoutType: WorkoutType = .custom
    var blocks: [WorkoutBlock]
    var validationError: String? {
        if version != 1 { return "This workout needs a newer app version." }
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Give this workout a name." }
        if blocks.isEmpty || blocks.count > 50 { return "Add between 1 and 50 blocks." }
        if Set(blocks.map(\.id)).count != blocks.count { return "Each block must have a unique identifier." }
        return blocks.compactMap(\.validationError).first
    }
    /// Ignores display names and UUIDs but includes the full performance prescription.
    var comparisonKey: String {
        blocks.map { b in
            "\(b.kind.rawValue):\(b.loadKg):\(b.bells):\(b.rounds):\(b.workSeconds):\(b.restSeconds):\(b.rungs):" + b.movements.map { "\($0.name.lowercased()):\($0.reps.map(String.init) ?? "?"):\($0.perSide)" }.joined(separator: ";")
        }.joined(separator: "|")
    }
    static func builtIn(_ config: WorkoutConfig) -> Self {
        var block = WorkoutBlock()
        block.loadKg = Double(config.weight)
        block.bells = config.kettlebellType == .double ? 2 : 1
        block.rounds = max(1, config.targetRounds)
        block.restSeconds = config.restDuration ?? 60
        switch config.workoutType {
        case .abc:
            block.name = "ABC complex"
            block.kind = config.mode == .emom ? .emom : .rounds
            block.movements = [.init(name: "Clean", reps: 2), .init(name: "Press", reps: 1), .init(name: "Front squat", reps: 3)]
        case .press:
            block.name = "Press ladder"
            block.kind = .ladder
            block.rounds = max(1, config.targetLadders)
            block.movements = [.init(name: "Press")]
        case .snatchTest:
            block.name = "Snatch intervals"
            block.kind = .emom
            block.bells = 1
            block.movements = [.init(name: "Snatch", reps: 20)]
        case .swingInterval:
            block.name = "Swing intervals"
            block.kind = .rounds
            block.movements = [.init(name: "Swing", reps: 10)]
        case .custom: break
        }
        return .init(name: block.name, workoutType: config.workoutType, blocks: [block])
    }
}

struct MovementReps: Codable, Hashable {
    var name: String
    var reps: Int
}

struct WorkoutSetResult: Codable, Hashable, Identifiable {
    var id = UUID()
    var blockID: UUID
    var setIndex: Int
    var duration: TimeInterval? = nil
    var repetitions: [MovementReps] = []
    var loadKg: Double
    var bells: Int
    var completed: Bool = true
    var totalReps: Int? { repetitions.isEmpty ? nil : repetitions.reduce(0) { $0 + $1.reps } }
}

enum SessionDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy, manageable, hard
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lb
    var id: String { rawValue }
    func display(_ kilograms: Double) -> Double { self == .kg ? kilograms : kilograms / 0.45359237 }
    func kilograms(_ value: Double) -> Double { self == .kg ? value : value * 0.45359237 }
    func label(_ kilograms: Double, bells: Int = 1) -> String {
        let number = display(kilograms).formatted(.number.precision(.fractionLength(0...2)))
        return "\(bells == 2 ? "2 × " : "")\(number) \(rawValue)"
    }
}

@Model final class WorkoutTemplate {
    var id: UUID = UUID()
    var name: String = "Workout"
    var definitionData: Data = Data()
    var isFavorite: Bool = false
    var modifiedAt: Date = Date()
    init(definition: WorkoutDefinition, isFavorite: Bool = false) {
        self.id = definition.id
        self.name = definition.name
        self.definitionData = (try? JSONEncoder().encode(definition)) ?? Data()
        self.isFavorite = isFavorite
    }
    var definition: WorkoutDefinition? {
        get { try? JSONDecoder().decode(WorkoutDefinition.self, from: definitionData) }
        set { if let newValue, let data = try? JSONEncoder().encode(newValue) { definitionData = data; name = newValue.name; modifiedAt = Date() } }
    }
}

@Model final class EquipmentRecord {
    var id: UUID = UUID()
    var weightKg: Double = 16
    var count: Int = 1
    var modifiedAt: Date = Date()
    init(weightKg: Double, count: Int) { self.weightKg = weightKg; self.count = count }
}
