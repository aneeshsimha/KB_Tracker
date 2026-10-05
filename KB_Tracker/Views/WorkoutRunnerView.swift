import SwiftUI
import SwiftData
import Combine

struct WorkoutRunnerView: View {
    @StateObject private var runtime: WorkoutRuntime
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var actualReps: [UUID: String] = [:]
    @State private var notes = ""
    @State private var difficulty: SessionDifficulty?
    @State private var showEnd = false
    @State private var showDiscard = false
    @State private var saveError: String?
    @State private var recoveryError = ActiveWorkoutStore.recoveryError()
    @AppStorage("kb_weight_unit") private var weightUnit: WeightUnit = .kg
    var onSaveComplete: (() -> Void)?

    init(definition: WorkoutDefinition, programID: UUID? = nil,
         onSaveComplete: (() -> Void)? = nil) {
        if let active = ActiveWorkoutStore.load() {
            _runtime = StateObject(wrappedValue: WorkoutRuntime(snapshot: active))
        } else {
            _runtime = StateObject(wrappedValue: WorkoutRuntime(definition: definition, programID: programID))
        }
        self.onSaveComplete = onSaveComplete
    }

    init(snapshot: ActiveWorkoutSnapshot, onSaveComplete: (() -> Void)? = nil) {
        _runtime = StateObject(wrappedValue: WorkoutRuntime(snapshot: snapshot))
        self.onSaveComplete = onSaveComplete
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    topBar
                    if let recoveryError {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(recoveryError).foregroundStyle(AppColors.red)
                            Button("Discard damaged recovery") {
                                do {
                                    try ActiveWorkoutStore.clear()
                                    self.recoveryError = nil
                                    runtime.retryPersistence()
                                } catch { saveError = error.localizedDescription }
                            }
                        }
                        .padding(14).background(AppColors.redDim, in: RoundedRectangle(cornerRadius: 12))
                    }
                    if runtime.isComplete { summary }
                    else { runner }
                }
                .padding(20)
            }
        }
        .foregroundStyle(AppColors.ink)
        .navigationBarBackButtonHidden()
        .onAppear {
            runtime.start()
            notes = runtime.snapshot.notes
            difficulty = runtime.snapshot.difficulty
        }
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { _ in
            runtime.refresh()
        }
        .onChange(of: notes) { _, value in
            guard runtime.isComplete else { return }
            runtime.setSummary(notes: value, difficulty: difficulty)
        }
        .onChange(of: difficulty) { _, value in
            guard runtime.isComplete else { return }
            runtime.setSummary(notes: notes, difficulty: value)
        }
        .confirmationDialog("End workout", isPresented: $showEnd) {
            Button("Save partial workout") { runtime.finishEarly() }
            Button("Discard workout", role: .destructive) { showDiscard = true }
            Button("Keep going", role: .cancel) { }
        } message: {
            Text("You can keep the sets you have logged or discard this workout.")
        }
        .alert("Discard workout?", isPresented: $showDiscard) {
            Button("Discard", role: .destructive) {
                runtime.discard()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This workout and its logged sets will be removed.")
        }
        .alert("Could not save workout", isPresented: Binding(
            get: { saveError != nil || runtime.persistenceError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: { Text(saveError ?? runtime.persistenceError ?? "Please try again.") }
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("WORKOUT").font(AppTypography.mono(11, weight: .semibold))
                    .foregroundStyle(AppColors.ink3)
                Text(runtime.snapshot.definition.name)
                    .font(AppTypography.titleMd)
            }
            Spacer()
            if !runtime.isComplete {
                Button("End") { showEnd = true }
                    .foregroundStyle(AppColors.red)
                    .accessibilityLabel("End workout")
            }
        }
    }

    private var runner: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("BLOCK \(runtime.snapshot.blockIndex + 1) OF \(runtime.snapshot.definition.blocks.count)")
                    .font(AppTypography.mono(12, weight: .semibold))
                    .foregroundStyle(AppColors.ink3)
                Spacer()
                Text(format(runtime.elapsed))
                    .font(AppTypography.mono(16))
                    .accessibilityLabel("Elapsed time \(format(runtime.elapsed))")
            }
            if let block = runtime.block {
                VStack(alignment: .leading, spacing: 16) {
                    Text(block.name).font(.system(size: 30, weight: .bold))
                    Text("\(block.kind.title) · \(weightUnit.label(block.loadKg, bells: block.bells))")
                        .foregroundStyle(AppColors.ink2)
                    HStack(alignment: .firstTextBaseline) {
                        Text(phaseTitle)
                            .font(AppTypography.mono(15, weight: .semibold))
                            .foregroundStyle(runtime.isLate ? AppColors.red : AppColors.ink2)
                        Spacer()
                        if let remaining = runtime.remaining {
                            Text(format(remaining))
                                .font(AppTypography.mono(46))
                                .monospacedDigit()
                                .accessibilityLabel("Remaining \(format(remaining))")
                        }
                    }
                    if runtime.snapshot.phase == .working {
                        Text("Set \(runtime.currentSetNumber) of \(block.targetSets)")
                            .font(AppTypography.mono(15))
                        if block.kind == .ladder, !block.rungs.isEmpty {
                            Text("Rung \(block.rungs[runtime.snapshot.setIndex % block.rungs.count])")
                                .font(AppTypography.mono(20))
                        }
                        movementInputs(block)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppColors.hairline))

                if runtime.snapshot.phase == .waitingNext {
                    Button("Start next block") { runtime.startNextBlock(); actualReps = [:] }
                        .buttonStyle(RunnerPrimaryStyle())
                } else if runtime.snapshot.phase == .working {
                    if block.kind == .emom && runtime.snapshot.activeSetStartedAt == nil {
                        Button("Begin set") { runtime.beginSet() }
                            .buttonStyle(RunnerPrimaryStyle())
                            .disabled(runtime.isCurrentSetLogged)
                    }
                    if canLogTarget(block) {
                        Button("Log target reps") { logTarget(block) }
                            .buttonStyle(RunnerPrimaryStyle())
                            .disabled(runtime.isCurrentSetLogged)
                    }
                    Button("Log actual reps") { log(block) }
                        .buttonStyle(RunnerSecondaryStyle())
                        .disabled(runtime.isCurrentSetLogged)
                }
                if runtime.snapshot.phase != .getReady && runtime.snapshot.phase != .waitingNext {
                    Button("Undo last set") { runtime.undo() }
                        .disabled(runtime.snapshot.results.isEmpty)
                        .foregroundStyle(AppColors.ink2)
                }
            }
            Button(runtime.isPaused ? "Resume" : "Pause") {
                runtime.isPaused ? runtime.resume() : runtime.pause()
            }
            .buttonStyle(RunnerSecondaryStyle())
            .accessibilityLabel(runtime.isPaused ? "Resume workout" : "Pause workout")
            if runtime.isPaused {
                Text("Paused").foregroundStyle(AppColors.ink2)
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }

    private var phaseTitle: String {
        if runtime.isPaused { return "PAUSED" }
        if runtime.isLate { return "SET OVERTIME" }
        switch runtime.snapshot.phase {
        case .getReady: return "GET READY"
        case .working: return "WORK"
        case .rest: return "REST"
        case .waitingNext: return "BLOCK COMPLETE"
        case .complete: return "COMPLETE"
        }
    }

    private func movementInputs(_ block: WorkoutBlock) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(block.movements) { movement in
                HStack {
                    VStack(alignment: .leading) {
                        Text(movement.name)
                        if let reps = movement.reps {
                            Text("Target \(reps)\(movement.perSide ? " per side" : "")")
                                .font(.caption).foregroundStyle(AppColors.ink3)
                        }
                    }
                    Spacer()
                    TextField("Actual", text: Binding(
                        get: { actualReps[movement.id] ?? "" },
                        set: { actualReps[movement.id] = $0 }
                    ))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 75)
                    .padding(10)
                    .background(AppColors.surface3, in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Actual total \(movement.name) reps\(movement.perSide ? ", both sides" : "")")
                }
            }
            Text("Leave actual reps blank if you did not count them.")
                .font(.caption).foregroundStyle(AppColors.ink3)
        }
    }

    private func log(_ block: WorkoutBlock) {
        let reps = block.movements.compactMap { movement -> MovementReps? in
            guard let value = Int(actualReps[movement.id] ?? ""), value >= 0 else { return nil }
            return MovementReps(name: movement.name, reps: value)
        }
        runtime.logSet(repetitions: reps)
        actualReps = [:]
    }

    private func canLogTarget(_ block: WorkoutBlock) -> Bool {
        block.kind == .ladder || block.movements.allSatisfy { $0.reps != nil }
    }

    private func logTarget(_ block: WorkoutBlock) {
        let reps: [MovementReps]
        if block.kind == .ladder, let movement = block.movements.first, !block.rungs.isEmpty {
            let target = block.rungs[runtime.snapshot.setIndex % block.rungs.count]
            reps = [.init(name: movement.name, reps: target * (movement.perSide ? 2 : 1))]
        } else {
            reps = block.movements.compactMap { movement in
                movement.reps.map { .init(name: movement.name, reps: $0 * (movement.perSide ? 2 : 1)) }
            }
        }
        runtime.logSet(repetitions: reps)
        actualReps = [:]
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(runtime.snapshot.isPartial ? "Partial workout" : "Workout complete")
                .font(.system(size: 34, weight: .bold))
            Text("\(runtime.completedSetCount) sets logged · \(format(runtime.elapsed))")
                .foregroundStyle(AppColors.ink2)
            if let reps = runtime.makeSession().recordedReps {
                Text("\(reps) recorded reps")
                    .font(AppTypography.mono(20))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("NOTES").font(AppTypography.mono(12))
                TextField("How did it feel?", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(AppColors.surface3, in: RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("DIFFICULTY").font(AppTypography.mono(12))
                HStack {
                    ForEach(SessionDifficulty.allCases) { option in
                        Button(option.title) { difficulty = option }
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(difficulty == option ? AppColors.ink : AppColors.surface3,
                                        in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(difficulty == option ? AppColors.background : AppColors.ink)
                    }
                }
            }
            Button("Save session") { save() }.buttonStyle(RunnerPrimaryStyle())
            Button("Discard workout") { showDiscard = true }
                .foregroundStyle(AppColors.red)
        }
    }

    private func save() {
        runtime.setSummary(notes: notes, difficulty: difficulty)
        do {
            try SessionRepository.save(runtime.makeSession(), context: modelContext)
            try ActiveWorkoutStore.clear()
            if let onSaveComplete { onSaveComplete() } else { dismiss() }
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func format(_ time: TimeInterval) -> String {
        let seconds = max(0, Int(time.rounded(.down)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct RunnerPrimaryStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold))
            .frame(maxWidth: .infinity).frame(minHeight: 54)
            .background(AppColors.ink.opacity(configuration.isPressed ? 0.75 : 1),
                        in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(AppColors.background)
    }
}

private struct RunnerSecondaryStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity).frame(minHeight: 48)
            .background(AppColors.surface3, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(AppColors.ink)
    }
}
