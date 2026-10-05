import SwiftUI
import SwiftData
import CoreData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WorkoutTemplate.modifiedAt, order: .reverse) private var templates: [WorkoutTemplate]
    @Query private var programs: [TrainingProgram]
    @AppStorage("kb_weight_unit") private var unit: WeightUnit = .kg
    @State private var selection: WorkoutType = .abc
    @State private var definition = WorkoutDefinition.builtIn(.emom(kettlebellType: .double, weight: 20, minutes: 20))
    @State private var route: HomeRoute?
    @State private var editing = false
    @State private var settings = false
    @State private var active: ActiveWorkoutSnapshot?
    @State private var message: String?
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Eyebrow("KB · TRACKER")
                    Spacer()
                    Button { route = .stats } label: { Image(systemName: "chart.bar") }.accessibilityLabel("Statistics")
                    Button { route = .history } label: { Image(systemName: "clock.arrow.circlepath") }.accessibilityLabel("Workout history")
                    Button { settings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings")
                }
                .buttonStyle(.bordered)
                if active != nil {
                    Button { route = .recovery } label: {
                        Label("Resume your workout", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity, alignment: .leading).padding()
                    }.kbCard()
                }
                if let program = programs.filter(\.isActive).sorted(by: { $0.modifiedAt > $1.modifiedAt }).first {
                    let next = ProgramService.nextDefinition(program: program)
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("UP NEXT")
                        Text(next.name).font(.title2.bold())
                        HStack {
                            Button("Start planned workout") { launch(next, programID: program.id) }
                            Spacer()
                            Button("View plan") { route = .program }
                        }
                    }.padding().kbCard()
                }
                HStack {
                    Button { route = .library } label: { Label("Workouts", systemImage: "square.stack") }
                    Spacer()
                    Button { route = .program } label: { Label("Program", systemImage: "calendar") }
                }.buttonStyle(.bordered)
                if let last = sessions.first {
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow("LAST SESSION")
                        Text(last.displayTitle).font(.title3.bold())
                        Text("\(last.workSets) sets · \(last.recordedReps.map { "\($0) reps" } ?? "Reps not recorded")")
                            .foregroundStyle(AppColors.ink2)
                        HStack {
                            Text(last.date, style: .date).font(.caption)
                            Spacer()
                            Button("Repeat") { definition = last.repeatDefinition; editing = true }
                        }
                    }.padding().kbCard()
                }
                Picker("Workout", selection: $selection) {
                    ForEach(WorkoutType.allCases.filter { $0 != .custom }) { type in
                        Text(type.title).tag(type)
                    }
                }.pickerStyle(.segmented)
                if let block = definition.blocks.first {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(definition.name).font(.title2.bold())
                            Spacer()
                            Button("Edit") { editing = true }
                        }
                        Text(unit.label(block.loadKg, bells: block.bells))
                            .font(AppTypography.mono(42, weight: .bold))
                            .minimumScaleFactor(0.6)
                        HStack {
                            Text(block.kind == .ladder ? "\(block.rounds) ladders" : "\(block.rounds) \(block.kind == .emom ? "minutes" : "rounds")")
                            Spacer()
                            Button { changeTarget(-1) } label: { Image(systemName: "minus.circle") }.accessibilityLabel("Decrease target")
                            Button { changeTarget(1) } label: { Image(systemName: "plus.circle") }.accessibilityLabel("Increase target")
                        }.font(.title3)
                        Text(block.movements.map { movement in
                            "\(movement.reps.map { "\($0) " } ?? "")\(movement.name)\(movement.perSide ? " each side" : "")"
                        }.joined(separator: " · ")).foregroundStyle(AppColors.ink2)
                        if definition.blocks.count > 1 { Text("\(definition.blocks.count) blocks").font(.caption) }
                    }.padding(20).kbCard()
                }
                PrimaryButton(title: "Start workout") { launch(definition) }
                Button("Save as preset") {
                    var copy = definition
                    copy.id = UUID()
                    context.insert(WorkoutTemplate(definition: copy, isFavorite: true))
                    do { try context.save(); WidgetSnapshotService.refresh(context: context); message = "Saved to Workouts." }
                    catch { message = error.localizedDescription }
                }.frame(maxWidth: .infinity)
                if !templates.filter(\.isFavorite).isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow("FAVORITES")
                        ForEach(templates.filter(\.isFavorite)) { template in
                            Button {
                                if let saved = template.definition { launch(saved) }
                            } label: {
                                HStack { Text(template.name); Spacer(); Image(systemName: "play.fill") }.padding()
                            }.kbCard()
                        }
                    }
                }
            }.padding(20)
        }
        .background(AppColors.background.ignoresSafeArea())
        .foregroundStyle(AppColors.ink)
        .navigationBarHidden(true)
        .navigationDestination(item: $route) { target in
            switch target {
            case .workout(let definition, let programID): WorkoutRunnerView(definition: definition, programID: programID)
            case .recovery:
                if let active { WorkoutRunnerView(snapshot: active) }
                else { Text("No active workout") }
            case .history: HistoryView()
            case .stats: StatsView()
            case .library: WorkoutLibraryView()
            case .program: ProgramView()
            }
        }
        .sheet(isPresented: $editing) {
            NavigationStack {
                WorkoutEditorView(definition: definition) { updated in
                    definition = updated
                    remember()
                    editing = false
                }
            }
        }
        .sheet(isPresented: $settings) { NavigationStack { SettingsView() } }
        .alert("KB Tracker", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) { message = nil }
        } message: { Text(message ?? "") }
        .onAppear {
            if !loaded { restoreSelection(); loaded = true }
            refresh()
            handlePendingLaunch()
        }
        .onChange(of: selection) { old, _ in remember(for: old); restoreSelection() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refresh(); handlePendingLaunch() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in refresh() }
        .onOpenURL { url in
            guard url.scheme == "kbtracker" else { return }
            switch url.host {
            case "next": handle(.init(action: .next))
            case "repeat": handle(.init(action: .repeatLast))
            case "preset": handle(.init(action: .preset, presetID: url.lastPathComponent))
            default: break
            }
        }
    }
    private func changeTarget(_ delta: Int) {
        guard !definition.blocks.isEmpty else { return }
        definition.blocks[0].rounds = min(500, max(1, definition.blocks[0].rounds + delta))
        remember()
    }
    private func remember(for type: WorkoutType? = nil) {
        if let data = try? JSONEncoder().encode(definition) { UserDefaults.standard.set(data, forKey: "kb-setup-\((type ?? selection).rawValue)") }
    }
    private func restoreSelection() {
        if let data = UserDefaults.standard.data(forKey: "kb-setup-\(selection.rawValue)"),
           let stored = try? JSONDecoder().decode(WorkoutDefinition.self, from: data), stored.validationError == nil {
            definition = stored
            return
        }
        let defaults = UserDefaults.standard
        let weight = defaults.object(forKey: "kb_pref_weight") as? Int ?? 20
        let kb = KBType(rawValue: defaults.string(forKey: "kb_pref_kbType") ?? "") ?? .double
        definition = .builtIn(.init(workoutType: selection, mode: selection == .swingInterval ? .rounds : .emom, kettlebellType: kb, weight: weight, targetRounds: 20, restDuration: 60, targetLadders: 5))
    }
    private func launch(_ value: WorkoutDefinition, programID: UUID? = nil) {
        if let error = value.validationError { message = error; return }
        active = ActiveWorkoutStore.load()
        if active != nil { route = .recovery }
        else { route = .workout(value, programID) }
    }
    private func refresh() {
        active = ActiveWorkoutStore.load()
        LiveActivityService.shared.reconcile(hasActiveWorkout: active != nil)
        do { try SessionRepository.reconcileDuplicates(context: context) }
        catch { message = error.localizedDescription }
        WidgetSnapshotService.refresh(context: context)
        if let program = programs.filter(\.isActive).sorted(by: { $0.modifiedAt > $1.modifiedAt }).first, program.remindersEnabled {
            Task { await NotificationService.scheduleProgram(days: program.weekdays, hour: program.reminderHour, minute: program.reminderMinute, override: program.rescheduledDate) }
        }
    }
    private func handlePendingLaunch() {
        if let request = WorkoutLaunchRequest.consume() { handle(request) }
    }
    private func handle(_ request: WorkoutLaunchRequest) {
        active = ActiveWorkoutStore.load()
        if active != nil { route = .recovery; return }
        switch request.action {
        case .next: route = .program
        case .repeatLast:
            if let last = sessions.first { launch(last.repeatDefinition) }
            else { message = "Save your first workout before repeating it." }
        case .preset:
            if let template = templates.first(where: { $0.id.uuidString == request.presetID }), let definition = template.definition { launch(definition) }
            else { message = "This preset is no longer available. Choose one from Workouts." }
        }
    }
}

private enum HomeRoute: Hashable, Identifiable {
    case workout(WorkoutDefinition, UUID?), recovery, history, stats, library, program
    var id: Self { self }
}
