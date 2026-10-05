import SwiftUI
import SwiftData

/// Records what actually happened. It intentionally never manufactures set
/// timestamps or durations from a prescribed workout.
struct ManualSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    private let editing: WorkoutSession?

    @State private var date: Date
    @State private var title: String
    @State private var load: Double
    @State private var bells: Int
    @State private var completed: Bool
    @State private var durationText: String
    @State private var notes: String
    @State private var resultRows: [ManualResult]
    @State private var error: String?
    @AppStorage("kb_weight_unit") private var unit: WeightUnit = .kg
    private var isManual: Bool { editing == nil || editing?.sourceRaw == "manual" }
    private var editsResults: Bool { editing?.sourceRaw != "legacy" }

    init(session: WorkoutSession? = nil) {
        editing = session
        _date = State(initialValue: session?.date ?? .now)
        _title = State(initialValue: session?.displayTitle ?? "Manual workout")
        _load = State(initialValue: session?.definition?.blocks.first?.loadKg ?? Double(session?.weight ?? 16))
        _bells = State(initialValue: session?.definition?.blocks.first?.bells ?? (session?.kettlebellType == .double ? 2 : 1))
        _completed = State(initialValue: session?.isCompleted ?? true)
        _durationText = State(initialValue: session.flatMap { SessionMetrics.measuredDuration($0) }.map { String(Int($0)) } ?? "")
        _notes = State(initialValue: session?.notes ?? "")
        _resultRows = State(initialValue: session?.results.map { result in
            ManualResult(result, block: session?.definition?.blocks.first(where: { $0.id == result.blockID }))
        } ?? [])
    }

    var body: some View {
        Form {
            Section("Session") {
                TextField("Workout name", text: $title)
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                Toggle("Completed", isOn: $completed)
                TextField("Total duration (seconds, optional)", text: $durationText).keyboardType(.decimalPad)
            }
            if editsResults { Section("Actual results") {
                ForEach($resultRows) { $row in
                    VStack(alignment: .leading) {
                        ForEach($row.measurements) { $measurement in
                            HStack { TextField("Movement", text: $measurement.name); TextField("Reps (optional)", text: $measurement.reps).keyboardType(.numberPad) }
                        }
                        if isManual { Button("Add movement") { row.measurements.append(.init()) }.font(.caption) }
                        TextField("Set duration seconds (optional)", text: $row.duration).keyboardType(.decimalPad)
                        Toggle("Set completed", isOn: $row.completed).font(.caption)
                    }
                }
                .onDelete { if isManual { resultRows.remove(atOffsets: $0) } }
                if isManual { Button("Add actual set") { resultRows.append(.init()) } }
            } }
            if isManual { Section("Load") {
                TextField("Load \(unit.rawValue)", value: Binding(get: { unit.display(load) }, set: { load = unit.kilograms($0) }), format: .number).keyboardType(.decimalPad)
                Picker("Bells", selection: $bells) { Text("1").tag(1); Text("2").tag(2) }.pickerStyle(.segmented)
            } }
            if !isManual, editing?.definition != nil { Section("Prescribed load") { Text("Loads stay as recorded for this workout.").foregroundColor(.secondary) } }
            Section("Notes") { TextField("Notes", text: $notes, axis: .vertical).lineLimit(3...) }
            if let error { Section { Text(error).foregroundColor(.red) } }
        }
        .navigationTitle(editing == nil ? "Add session" : "Edit session")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
        }
    }

    private func save() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { error = "Enter a workout name."; return }
        guard !isManual || (load.isFinite && load > 0 && load <= 500 && (1...2).contains(bells)) else { error = "Enter a load between 0 and 500 kg."; return }
        guard durationText.isEmpty || (Double(durationText).map { $0.isFinite && $0 > 0 } ?? false), !editsResults || resultRows.allSatisfy({ !$0.measurements.isEmpty && $0.measurements.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && ($0.reps.isEmpty || (Int($0.reps).map { $0 >= 0 } ?? false)) } && ($0.duration.isEmpty || (Double($0.duration).map { $0.isFinite && $0 >= 0 } ?? false)) }) else { error = "Enter movement names and non-negative reps/durations."; return }
        let session = editing ?? WorkoutSession()
        let manual = isManual
        let blockID = session.definition?.blocks.first?.id ?? UUID()
        if manual {
            let movements = resultRows.flatMap(\.measurements).compactMap { row -> WorkoutMovement? in let name = row.name.trimmingCharacters(in: .whitespacesAndNewlines); return name.isEmpty ? nil : WorkoutMovement(name: name) }
            let block = WorkoutBlock(id: blockID, name: cleanTitle, kind: .rounds, movements: movements.isEmpty ? [WorkoutMovement(name: "Recorded movement")] : movements, loadKg: load, bells: bells, rounds: max(1, resultRows.count), workSeconds: 60, restSeconds: 0)
            session.definition = WorkoutDefinition(id: session.definition?.id ?? UUID(), name: cleanTitle, workoutType: .custom, blocks: [block])
            session.workoutType = .custom; session.mode = .rounds
            session.weight = Int(load.rounded()); session.kettlebellType = bells == 2 ? .double : .single
        } else if var definition = session.definition { definition.name = cleanTitle; session.definition = definition }
        session.date = date
        session.isCompleted = completed; session.totalDuration = Double(durationText) ?? 0; session.notes = notes.isEmpty ? nil : notes
        session.endedAt = session.totalDuration > 0 ? date.addingTimeInterval(session.totalDuration) : nil
        if editsResults { session.results = resultRows.enumerated().map { index, row in row.result(blockID: blockID, index: index, load: load, bells: bells, reindex: manual) } }
        if manual { session.completedRounds = session.results.filter(\.completed).count; session.targetRounds = max(1, session.results.count) }
        if editing == nil { session.setTimes = []; session.sourceRaw = "manual" } // manual entries have no fabricated legacy timings
        session.modifiedAt = .now
        do {
            try SessionRepository.save(session, context: modelContext)
            dismiss()
        } catch { self.error = "Could not save this session. \(error.localizedDescription)" }
    }
}

private struct ManualResult: Identifiable {
    var id = UUID()
    var measurements: [ManualMeasurement] = [.init()]
    var duration = ""
    var completed = true
    var originalBlockID: UUID? = nil
    var originalLoad: Double? = nil
    var originalBells: Int? = nil
    var originalSetIndex: Int? = nil
    init() {}
    init(_ result: WorkoutSetResult, block: WorkoutBlock? = nil) {
        id = result.id
        measurements = result.repetitions.isEmpty ? (block?.movements.map { .init(name: $0.name) } ?? [.init()]) : result.repetitions.map { .init(name: $0.name, reps: String($0.reps)) }
        duration = result.duration.map { String($0) } ?? ""; completed = result.completed; originalBlockID = result.blockID; originalLoad = result.loadKg; originalBells = result.bells; originalSetIndex = result.setIndex
    }
    func result(blockID: UUID, index: Int, load: Double, bells: Int, reindex: Bool) -> WorkoutSetResult {
        let actual = measurements.compactMap { value -> MovementReps? in let name = value.name.trimmingCharacters(in: .whitespacesAndNewlines); guard !name.isEmpty, let reps = Int(value.reps) else { return nil }; return .init(name: name, reps: reps) }
        return WorkoutSetResult(id: id, blockID: reindex ? blockID : (originalBlockID ?? blockID), setIndex: reindex ? index : (originalSetIndex ?? index), duration: Double(duration), repetitions: actual, loadKg: reindex ? load : (originalLoad ?? load), bells: reindex ? bells : (originalBells ?? bells), completed: completed)
    }
}

private struct ManualMeasurement: Identifiable { var id = UUID(); var name = ""; var reps = "" }
