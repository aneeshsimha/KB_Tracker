import SwiftUI

struct WorkoutEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var definition: WorkoutDefinition
    @State private var unit: WeightUnit = .kg
    @State private var attemptedSave = false
    @State private var rungDrafts: [UUID: String] = [:]
    let onSave: (WorkoutDefinition) -> Void

    init(definition: WorkoutDefinition, onSave: @escaping (WorkoutDefinition) -> Void) {
        _definition = State(initialValue: definition)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    TextField("Workout name", text: $definition.name)
                    Picker("Display loads", selection: $unit) {
                        Text("kg").tag(WeightUnit.kg)
                        Text("lb").tag(WeightUnit.lb)
                    }
                    .pickerStyle(.segmented)
                    if attemptedSave, definition.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        error("Give this workout a name.")
                    }
                }

                ForEach($definition.blocks) { $block in
                    Section {
                        HStack {
                            TextField("Block name", text: $block.name)
                            Spacer()
                            Button { moveBlock(block.id, by: -1) } label: { Image(systemName: "arrow.up") }
                                .accessibilityLabel("Move block up")
                            Button { moveBlock(block.id, by: 1) } label: { Image(systemName: "arrow.down") }
                                .accessibilityLabel("Move block down")
                            Button(role: .destructive) { definition.blocks.removeAll { $0.id == block.id } } label: {
                                Image(systemName: "trash")
                            }
                        }
                        Picker("Block type", selection: $block.kind) {
                            ForEach(BlockKind.allCases) { kind in Text(kind.title).tag(kind) }
                        }
                        HStack {
                            Text("Load per bell")
                            Spacer()
                            TextField("Load", value: loadBinding(for: $block), format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text(unit.rawValue).foregroundStyle(AppColors.ink3)
                        }
                        Stepper("\(block.bells) \(block.bells == 1 ? "bell" : "bells")", value: $block.bells, in: 1...2)
                        if block.kind == .warmup || block.kind == .cooldown {
                            numberField("Duration (seconds)", value: $block.workSeconds)
                        } else {
                            numberField(block.kind == .emom ? "Minutes" : block.kind == .ladder ? "Ladders" : "Rounds", value: $block.rounds)
                            if block.kind == .interval { numberField("Work (seconds)", value: $block.workSeconds) }
                            if block.kind == .emom { Text("Work begins every 60 seconds.").font(.caption).foregroundStyle(AppColors.ink3) }
                            if block.kind != .ladder { numberField("Rest (seconds)", value: $block.restSeconds) }
                        }
                        if block.kind == .ladder {
                            HStack {
                                Text("Rungs")
                                Spacer()
                                TextField("2, 3, 5, 10", text: rungBinding(for: $block))
                                    .keyboardType(.numbersAndPunctuation)
                                    .multilineTextAlignment(.trailing)
                            }
                            if attemptedSave, Self.parseRungs(rungDrafts[block.id] ?? block.rungs.map(String.init).joined(separator: ", ")) == nil {
                                error("Enter 1–20 comma-separated positive rungs.")
                            }
                        }
                        ForEach($block.movements) { $movement in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    TextField("Movement", text: $movement.name)
                                    Button(role: .destructive) { block.movements.removeAll { $0.id == movement.id } } label: { Image(systemName: "minus.circle") }
                                }
                                HStack {
                                    Text("Reps")
                                    Spacer()
                                    TextField("Unknown", text: repsBinding(for: $movement))
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 90)
                                }
                                Toggle("Per side", isOn: $movement.perSide)
                            }
                        }
                        Button("Add movement") { block.movements.append(WorkoutMovement(name: "", reps: nil)) }
                        if attemptedSave, let message = block.validationError { error(message) }
                    } header: {
                        Text(block.name.isEmpty ? "Block" : block.name)
                    }
                }
                .onMove { source, destination in definition.blocks.move(fromOffsets: source, toOffset: destination) }
                .onDelete { offsets in definition.blocks.remove(atOffsets: offsets) }
                Section {
                    Button("Add block") { definition.blocks.append(WorkoutBlock(name: "New block")) }
                    if attemptedSave, let message = definition.validationError { error(message) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .foregroundStyle(AppColors.ink)
            .tint(AppColors.green)
            .navigationTitle("Workout builder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { EditButton() }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        attemptedSave = true
                        for index in definition.blocks.indices {
                            if definition.blocks[index].kind == .emom { definition.blocks[index].workSeconds = 60 }
                            if definition.blocks[index].kind == .ladder {
                                let block = definition.blocks[index]
                                guard let parsed = Self.parseRungs(rungDrafts[block.id] ?? block.rungs.map(String.init).joined(separator: ", ")) else { return }
                                definition.blocks[index].rungs = parsed
                            }
                        }
                        guard definition.validationError == nil else { return }
                        if !Self.preservesBuiltinIdentity(definition) { definition.workoutType = .custom }
                        onSave(definition)
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            for block in definition.blocks where block.kind == .ladder {
                rungDrafts[block.id] = block.rungs.map(String.init).joined(separator: ", ")
            }
        }
    }

    private func error(_ message: String) -> some View {
        Text(message).font(.footnote).foregroundStyle(AppColors.red)
    }

    private func numberField(_ title: String, value: Binding<Int>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
        }
    }

    private func loadBinding(for block: Binding<WorkoutBlock>) -> Binding<Double> {
        Binding(get: { unit.display(block.wrappedValue.loadKg) }, set: { block.wrappedValue.loadKg = unit.kilograms($0) })
    }
    private func rungBinding(for block: Binding<WorkoutBlock>) -> Binding<String> {
        Binding(get: { rungDrafts[block.wrappedValue.id] ?? block.wrappedValue.rungs.map(String.init).joined(separator: ", ") }, set: { text in
            rungDrafts[block.wrappedValue.id] = text
        })
    }
    static func parseRungs(_ text: String) -> [Int]? {
        let parts = text.split(separator: ",", omittingEmptySubsequences: false)
        guard (1...20).contains(parts.count) else { return nil }
        let values = parts.map { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        guard values.allSatisfy({ $0 != nil && (1...1000).contains($0!) }) else { return nil }
        return values.compactMap { $0 }
    }
    static func preservesBuiltinIdentity(_ workout: WorkoutDefinition) -> Bool {
        guard workout.blocks.count == 1, let block = workout.blocks.first else { return false }
        let movements = block.movements.map { ($0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), $0.reps, $0.perSide) }
        switch workout.workoutType {
        case .abc:
            return (block.kind == .emom || block.kind == .rounds) && movements.count == 3
                && movements[0].0 == "clean" && movements[0].1 == 2 && !movements[0].2
                && movements[1].0 == "press" && movements[1].1 == 1 && !movements[1].2
                && movements[2].0 == "front squat" && movements[2].1 == 3 && !movements[2].2
        case .press:
            return block.kind == .ladder && block.rungs == [2, 3, 5, 10]
                && movements.count == 1 && movements[0].0 == "press" && movements[0].1 == nil && !movements[0].2
        case .snatchTest:
            return block.kind == .emom && movements.count == 1 && movements[0].0 == "snatch" && movements[0].1 == 20 && !movements[0].2
        case .swingInterval:
            return block.kind == .rounds && movements.count == 1 && movements[0].0 == "swing" && movements[0].1 == 10 && !movements[0].2
        case .custom:
            return false
        }
    }
    private func repsBinding(for movement: Binding<WorkoutMovement>) -> Binding<String> {
        Binding(get: { movement.wrappedValue.reps.map(String.init) ?? "" }, set: { text in
            movement.wrappedValue.reps = text.isEmpty ? nil : (Int(text) ?? 0)
        })
    }

    private func moveBlock(_ id: UUID, by offset: Int) {
        guard let index = definition.blocks.firstIndex(where: { $0.id == id }),
              definition.blocks.indices.contains(index + offset) else { return }
        definition.blocks.swapAt(index, index + offset)
    }
}
