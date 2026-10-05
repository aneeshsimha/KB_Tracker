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

    init(session: WorkoutSession? = nil) {
        editing = session
        _date = State(initialValue: session?.date ?? .now)
        _title = State(initialValue: session?.displayTitle ?? "Manual workout")
        _load = State(initialValue: session?.definition?.blocks.first?.loadKg ?? Double(session?.weight ?? 16))
        _bells = State(initialValue: session?.definition?.blocks.first?.bells ?? (session?.kettlebellType == .double ? 2 : 1))
        _completed = State(initialValue: session?.isCompleted ?? true)
        _durationText = State(initialValue: session.flatMap { SessionMetrics.measuredDuration($0) }.map { String(Int($0)) } ?? "")
        _notes = State(initialValue: session?.notes ?? "")
        _resultRows = State(initialValue: session?.results.map(ManualResult.init) ?? [])
    }

    var body: some View {
        Form {
            Section("Session") {
                TextField("Workout name", text: $title)
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                Toggle("Completed", isOn: $completed)
                TextField("Total duration (seconds, optional)", text: $durationText).keyboardType(.decimalPad)
            }
            Section("Actual results") {
                ForEach($resultRows) { $row in
                    VStack(alignment: .leading) {
                        TextField("Movement", text: $row.movement)
                        HStack {
                            TextField("Reps (optional)", text: $row.reps).keyboardType(.numberPad)
                            TextField("Set duration seconds (optional)", text: $row.duration).keyboardType(.decimalPad)
                        }
                        Toggle("Set completed", isOn: $row.completed).font(.caption)
                    }
                }
                .onDelete { resultRows.remove(atOffsets: $0) }
                Button("Add actual set") { resultRows.append(.init()) }
            }
            Section("Load") {
                TextField("Load kg", value: $load, format: .number).keyboardType(.decimalPad)
                Picker("Bells", selection: $bells) { Text("1").tag(1); Text("2").tag(2) }.pickerStyle(.segmented)
            }
            Section("Notes") { TextField("Notes", text: $notes, axis: .vertical).lineLimit(3...) }
            if let error { Section { Text(error).foregroundColor(.red) } }
        }
        .navigationTitle(editing == nil ? "Add session" : "Edit session")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
        }
    }

    private func save() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, load.isFinite, load > 0, (1...2).contains(bells) else { error = "Enter a workout name and valid load."; return }
        guard durationText.isEmpty || (Double(durationText).map { $0.isFinite && $0 > 0 } ?? false), resultRows.allSatisfy({ ($0.reps.isEmpty || (Int($0.reps).map { $0 >= 0 } ?? false)) && ($0.duration.isEmpty || (Double($0.duration).map { $0.isFinite && $0 >= 0 } ?? false)) }) else { error = "Reps and durations must be non-negative numbers."; return }
        let session = editing ?? WorkoutSession()
        let isManual = editing == nil || session.sourceRaw == "manual"
        let blockID = session.definition?.blocks.first?.id ?? UUID()
        if isManual {
            let movements = resultRows.compactMap { row -> WorkoutMovement? in let name = row.movement.trimmingCharacters(in: .whitespacesAndNewlines); return name.isEmpty ? nil : WorkoutMovement(name: name) }
            let block = WorkoutBlock(id: blockID, name: cleanTitle, kind: .rounds, movements: movements.isEmpty ? [WorkoutMovement(name: "Recorded movement")] : movements, loadKg: load, bells: bells, rounds: max(1, resultRows.count), workSeconds: 60, restSeconds: 0)
            session.definition = WorkoutDefinition(id: session.definition?.id ?? UUID(), name: cleanTitle, workoutType: .custom, blocks: [block])
            session.weight = Int(load.rounded()); session.kettlebellType = bells == 2 ? .double : .single
        }
        session.date = date
        session.isCompleted = completed; session.totalDuration = Double(durationText) ?? 0; session.notes = notes.isEmpty ? nil : notes
        session.endedAt = session.totalDuration > 0 ? date.addingTimeInterval(session.totalDuration) : nil
        session.results = resultRows.enumerated().map { index, row in row.result(blockID: blockID, index: index, load: load, bells: bells) }
        if isManual { session.completedRounds = session.results.filter(\.completed).count; session.targetRounds = max(1, session.results.count) }
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
    var movement = ""
    var reps = ""
    var duration = ""
    var completed = true
    var originalBlockID: UUID? = nil
    var originalLoad: Double? = nil
    var originalBells: Int? = nil
    var originalRepetitions: [MovementReps] = []
    var originalSetIndex: Int? = nil
    init() {}
    init(_ result: WorkoutSetResult) {
        id = result.id; movement = result.repetitions.first?.name ?? ""; reps = result.totalReps.map(String.init) ?? ""; duration = result.duration.map { String($0) } ?? ""; completed = result.completed; originalBlockID = result.blockID; originalLoad = result.loadKg; originalBells = result.bells; originalRepetitions = result.repetitions; originalSetIndex = result.setIndex
    }
    func result(blockID: UUID, index: Int, load: Double, bells: Int) -> WorkoutSetResult {
        let unchanged = movement == originalRepetitions.first?.name && reps == originalRepetitions.reduce(0, { $0 + $1.reps }).description
        let actual = movement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Int(reps) == nil ? [] : [.init(name: movement, reps: Int(reps)!)]
        return WorkoutSetResult(id: id, blockID: originalBlockID ?? blockID, setIndex: originalSetIndex ?? index, duration: Double(duration), repetitions: unchanged ? originalRepetitions : actual, loadKg: originalLoad ?? load, bells: originalBells ?? bells, completed: completed)
    }
}
