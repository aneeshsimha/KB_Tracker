import SwiftUI
import SwiftData
import UserNotifications

struct ProgramView: View {
    @Environment(\.modelContext) private var context
    @Query private var programs: [TrainingProgram]
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \EquipmentRecord.weightKg) private var bells: [EquipmentRecord]
    @State private var running: WorkoutDefinition?
    @State private var rescheduleDate = Date()
    @State private var bellSelection = 0.0
    @State private var showNextBell = false
    @State private var movingDay: Int?
    @State private var reminderMessage: String?
    @State private var saveError: String?

    private var program: TrainingProgram? { programs.first }
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        ScrollView {
            if let program {
                VStack(alignment: .leading, spacing: 20) {
                    upNext(program)
                    schedule(program)
                    progression(program)
                    templateMode(program)
                    reminders(program)
                    week(program)
                    if !program.lastDecision.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Eyebrow("LAST ADJUSTMENT")
                            Text(program.lastDecision).font(AppTypography.bodyText).foregroundStyle(AppColors.ink2)
                        }.padding(16).frame(maxWidth: .infinity, alignment: .leading).kbCard()
                    }
                    if !program.decisionHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow("ADJUSTMENT HISTORY")
                            ForEach(program.decisionHistory.reversed()) { decision in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(decision.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(AppTypography.mono(11)).foregroundStyle(AppColors.ink3)
                                    Text(decision.message).font(.caption).foregroundStyle(AppColors.ink2)
                                }
                            }
                        }.padding(16).frame(maxWidth: .infinity, alignment: .leading).kbCard()
                    }
                }
                .padding(20)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Program")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if programs.isEmpty {
                let created = TrainingProgram()
                context.insert(created)
                persist(created)
            }
        }
        .alert("Could not save program", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK") { saveError = nil }
        } message: { Text(saveError ?? "Please try again.") }
        .navigationDestination(item: $running) { definition in
            WorkoutRunnerView(definition: definition, programID: program?.id)
        }
        .sheet(isPresented: $showNextBell) {
            NavigationStack {
                Form {
                    Section("Choose the next bell") {
                        if let program {
                            let current = program.pendingBellTargetRaw == "press" ? program.pressWeightKg : program.abcWeightKg
                            let needed = program.pendingBellTargetRaw == "press" ? program.pressBells : program.abcBells
                            let eligible = bells.filter { $0.weightKg > current && $0.count >= needed }
                            if eligible.isEmpty {
                                Text("Add a heavier \(needed == 2 ? "pair" : "bell") in Equipment to continue.")
                            }
                            ForEach(eligible) { bell in
                                Button(WeightUnit.kg.label(bell.weightKg, bells: needed)) { bellSelection = bell.weightKg }
                                    .foregroundStyle(bellSelection == bell.weightKg ? AppColors.green : AppColors.ink)
                            }
                        }
                    }
                }
                .navigationTitle("Next bell")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showNextBell = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Use bell") {
                            if let program { ProgramService.approveNextBell(program: program, weightKg: bellSelection); persist(program) }
                            showNextBell = false
                        }
                        .disabled(program.map { plan in
                            let current = plan.pendingBellTargetRaw == "press" ? plan.pressWeightKg : plan.abcWeightKg
                            let needed = plan.pendingBellTargetRaw == "press" ? plan.pressBells : plan.abcBells
                            return !bells.contains { $0.weightKg == bellSelection && $0.weightKg > current && $0.count >= needed }
                        } ?? true)
                    }
                }
            }.preferredColorScheme(.dark)
        }
    }

    private func upNext(_ program: TrainingProgram) -> some View {
        let definition = ProgramService.nextDefinition(program: program)
        return VStack(alignment: .leading, spacing: 12) {
            Eyebrow("UP NEXT")
            Text(definition.name).font(AppTypography.titleMd).foregroundStyle(AppColors.ink)
            Text(definition.blocks.map { "\($0.name) · \($0.rounds) \($0.kind == .emom ? "min" : $0.kind == .ladder ? "ladders" : "rounds") · \(WeightUnit.kg.label($0.loadKg, bells: $0.bells))" }.joined(separator: "\n"))
                .font(AppTypography.mono(12)).foregroundStyle(AppColors.ink2)
            Text("Planned \(nextDate(program).formatted(date: .abbreviated, time: .omitted))")
                .font(AppTypography.mono(12)).foregroundStyle(AppColors.ink3)
            PrimaryButton(title: program.usesTemplates && program.templateDefinitions.isEmpty ? "Choose a template" : "Start planned workout") { running = definition }
                .disabled(program.usesTemplates && program.templateDefinitions.isEmpty)
            if program.pendingBellApproval {
                GhostButton(title: "Choose next bell") {
                    bellSelection = program.pendingBellTargetRaw == "press" ? program.pressWeightKg : program.abcWeightKg
                    showNextBell = true
                }
            }
            DisclosureGroup("Change next session") {
                DatePicker("Reschedule", selection: $rescheduleDate, in: earliestRescheduleDate..., displayedComponents: .date)
                Button("Use this date") { reschedule(program); refreshReminder(program) }
                if program.rescheduledDate != nil {
                    Button("Return to schedule") { clearReschedule(program); refreshReminder(program) }
                }
                if program.usesTemplates {
                    ForEach(templates) { template in
                        if let definition = template.definition, definition.validationError == nil {
                            Button("Next: \(definition.name)") { program.nextOverride = definition; persist(program) }
                        }
                    }
                } else {
                    Button("Next: ABC") { program.nextOverride = ProgramService.builtInDefinition(program: program, type: .abc); persist(program) }
                    Button("Next: Press") { program.nextOverride = ProgramService.builtInDefinition(program: program, type: .press); persist(program) }
                }
                if program.nextOverride != nil { Button("Clear override") { program.nextOverride = nil; persist(program) } }
            }
            .font(AppTypography.bodyText)
            .tint(AppColors.green)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).kbCard()
        .onAppear { rescheduleDate = max(earliestRescheduleDate, program.rescheduledDate ?? nextDate(program)) }
    }

    private func schedule(_ program: TrainingProgram) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("WEEKLY SCHEDULE")
            Picker("Days per week", selection: Binding(get: { program.weekdays.count }, set: { n in
                program.weekdays = n == 2 ? [2, 5] : n == 3 ? [2, 4, 6] : [2, 3, 5, 6]
                persist(program)
                refreshReminder(program)
            })) {
                Text("2 days").tag(2); Text("3 days").tag(3); Text("4 days").tag(4)
            }.pickerStyle(.segmented)
            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { day in
                    Button {
                        if program.weekdays.contains(day) { movingDay = day }
                        else if let movingDay {
                            var selected = program.weekdays
                            selected.removeAll { $0 == movingDay }
                            selected.append(day)
                            program.weekdays = selected
                            self.movingDay = nil
                            persist(program)
                            refreshReminder(program)
                        }
                    } label: {
                        Text(dayNames[day - 1])
                            .font(AppTypography.mono(11, weight: .semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .foregroundStyle(program.weekdays.contains(day) ? AppColors.background : AppColors.ink2)
                            .background(movingDay == day ? AppColors.green : program.weekdays.contains(day) ? AppColors.ink : AppColors.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            Text(movingDay == nil ? "Tap a selected day, then its replacement." : "Now choose a replacement day.")
                .font(.caption).foregroundStyle(AppColors.ink3)
        }.padding(16).kbCard()
    }

    private func progression(_ program: TrainingProgram) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("PROGRESSION")
            Toggle("Adjust targets automatically", isOn: Binding(get: { program.autoProgress }, set: { program.autoProgress = $0; persist(program) }))
                .tint(AppColors.green)
            if !program.usesTemplates {
                Picker("ABC mode", selection: Binding(get: { program.abcMode }, set: { program.abcMode = $0; persist(program) })) {
                    Text("EMOM").tag(WorkoutMode.emom); Text("Rounds").tag(WorkoutMode.rounds)
                }.pickerStyle(.segmented)
                Stepper("ABC \(program.abcMode == .emom ? "minutes" : "rounds"): \(program.abcMode == .emom ? program.abcMinutes : program.abcRounds)", onIncrement: {
                    if program.abcMode == .emom { program.abcMinutes = min(30, program.abcMinutes + 1); program.abcStartMinutes = program.abcMinutes }
                    else { program.abcRounds = min(20, program.abcRounds + 1); program.abcStartRounds = program.abcRounds }; persist(program)
                }, onDecrement: {
                    if program.abcMode == .emom { program.abcMinutes = max(1, program.abcMinutes - 1); program.abcStartMinutes = program.abcMinutes }
                    else { program.abcRounds = max(1, program.abcRounds - 1); program.abcStartRounds = program.abcRounds }; persist(program)
                })
                Stepper("Press ladders: \(program.pressLadders)", value: Binding(get: { program.pressLadders }, set: { program.pressLadders = $0; program.pressStartLadders = $0; persist(program) }), in: 1...10)
                Menu("ABC bells: \(WeightUnit.kg.label(program.abcWeightKg, bells: program.abcBells))") {
                    ForEach(bells) { bell in
                        Button(WeightUnit.kg.label(bell.weightKg)) {
                            program.abcWeightKg = bell.weightKg; program.abcBells = 1; persist(program)
                        }
                        if bell.count >= 2 {
                            Button(WeightUnit.kg.label(bell.weightKg, bells: 2)) {
                                program.abcWeightKg = bell.weightKg; program.abcBells = 2; persist(program)
                            }
                        }
                    }
                }
                Menu("Press bells: \(WeightUnit.kg.label(program.pressWeightKg, bells: program.pressBells))") {
                    ForEach(bells) { bell in
                        Button(WeightUnit.kg.label(bell.weightKg)) {
                            program.pressWeightKg = bell.weightKg; program.pressBells = 1; persist(program)
                        }
                        if bell.count >= 2 {
                            Button(WeightUnit.kg.label(bell.weightKg, bells: 2)) {
                                program.pressWeightKg = bell.weightKg; program.pressBells = 2; persist(program)
                            }
                        }
                    }
                }
                if bells.isEmpty { Text("Add your bells in Equipment to choose a starting load.").font(.caption).foregroundStyle(AppColors.ink3) }
                Text("Two successful sessions at the same target add one minute, round, or ladder. Two hard or incomplete sessions reduce the target by 20%.")
                    .font(.caption).foregroundStyle(AppColors.ink3)
            }
        }.padding(16).kbCard()
    }

    private func templateMode(_ program: TrainingProgram) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("WORKOUT SEQUENCE")
            Toggle("Use my templates", isOn: Binding(get: { program.usesTemplates }, set: { program.usesTemplates = $0; program.nextIndex = 0; persist(program) }))
                .tint(AppColors.green)
            if program.usesTemplates {
                Text("Select templates in order. These sessions follow your schedule without automatic progression.")
                    .font(.caption).foregroundStyle(AppColors.ink3)
                ForEach(templates) { template in
                    if let definition = template.definition, definition.validationError == nil {
                        let included = program.templateDefinitions.contains { $0.id == definition.id }
                        Button {
                            var sequence = program.templateDefinitions
                            if included { sequence.removeAll { $0.id == definition.id } }
                            else { sequence.append(definition) }
                            program.templateDefinitions = sequence
                            persist(program)
                        } label: {
                            HStack {
                                Image(systemName: included ? "checkmark.circle.fill" : "circle")
                                Text(definition.name)
                                Spacer()
                            }.foregroundStyle(included ? AppColors.green : AppColors.ink2)
                        }
                    }
                }
                if program.templateDefinitions.isEmpty { Text("Choose at least one template. ABC is shown until then.").font(.caption).foregroundStyle(AppColors.ink3) }
            } else {
                Text("ABC and Press alternate after each completed planned session.")
                    .font(.caption).foregroundStyle(AppColors.ink3)
            }
        }.padding(16).kbCard()
    }

    private func reminders(_ program: TrainingProgram) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("REMINDERS")
            Toggle("Workout reminders", isOn: Binding(get: { program.remindersEnabled }, set: { program.remindersEnabled = $0; persist(program); refreshReminder(program) }))
                .tint(AppColors.green)
            if program.remindersEnabled {
                DatePicker("Time", selection: Binding(get: {
                    Calendar.current.date(from: DateComponents(hour: program.reminderHour, minute: program.reminderMinute)) ?? Date()
                }, set: { date in
                    let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                    program.reminderHour = parts.hour ?? 8
                    program.reminderMinute = parts.minute ?? 0
                    persist(program)
                    refreshReminder(program)
                }), displayedComponents: .hourAndMinute)
            }
            if let reminderMessage {
                Text(reminderMessage).font(.caption).foregroundStyle(AppColors.red)
            }
        }.padding(16).kbCard()
    }

    private func week(_ program: TrainingProgram) -> some View {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let start = calendar.date(byAdding: .day, value: -(weekday - 1), to: calendar.startOfDay(for: today)) ?? today
        let weekSessions = sessions.filter { $0.programID == program.id && $0.isCompleted && $0.date >= start }
        let plannedDates = ProgramService.plannedDates(program: program, inWeekStarting: start)
        let planned = plannedDates.count
        let completedPlanned = plannedDates.filter { date in
            weekSessions.contains { calendar.isDate($0.date, inSameDayAs: date) }
        }.count
        return VStack(alignment: .leading, spacing: 12) {
            Eyebrow("THIS WEEK")
            Text("\(completedPlanned) / \(planned) planned sessions")
                .font(AppTypography.mono(22, weight: .semibold)).foregroundStyle(AppColors.ink)
            ForEach(plannedDates, id: \.self) { date in
                    let complete = weekSessions.contains { calendar.isDate($0.date, inSameDayAs: date) }
                    HStack {
                        Image(systemName: complete ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(complete ? AppColors.green : AppColors.ink3)
                        Text(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        Spacer()
                        Text(complete ? "Completed" : date < calendar.startOfDay(for: today) ? "Missed" : "Planned")
                            .foregroundStyle(AppColors.ink3)
                    }.font(AppTypography.mono(12))
            }
        }.padding(16).kbCard()
    }

    private func nextDate(_ program: TrainingProgram) -> Date {
        if let override = program.rescheduledDate { return override }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for offset in 0...7 {
            if let date = calendar.date(byAdding: .day, value: offset, to: today),
               program.weekdays.contains(calendar.component(.weekday, from: date)),
               !sessions.contains(where: { $0.programID == program.id && $0.isCompleted && calendar.isDate($0.date, inSameDayAs: date) }) { return date }
        }
        return today
    }

    private var earliestRescheduleDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    }

    private func reschedule(_ program: TrainingProgram) {
        guard rescheduleDate >= earliestRescheduleDate else { return }
        let calendar = Calendar.current
        var history = program.rescheduleHistory
        let previous = program.rescheduledDate
        let existingIndex = previous.flatMap { prior in history.lastIndex(where: { calendar.isDate($0.movedDate, inSameDayAs: prior) }) }
        let planned = existingIndex.map { history[$0].plannedDate } ?? nextDate(program)
        let move = ProgramReschedule(plannedDate: calendar.startOfDay(for: planned), movedDate: calendar.startOfDay(for: rescheduleDate))
        if let existingIndex { history[existingIndex] = move } else { history.append(move) }
        program.rescheduleHistory = history
        program.rescheduledDate = move.movedDate
        persist(program)
    }

    private func clearReschedule(_ program: TrainingProgram) {
        guard let active = program.rescheduledDate else { return }
        let calendar = Calendar.current
        var history = program.rescheduleHistory
        if let index = history.lastIndex(where: { calendar.isDate($0.movedDate, inSameDayAs: active) }) { history.remove(at: index) }
        program.rescheduleHistory = history
        program.rescheduledDate = nil
        persist(program)
    }

    private func persist(_ program: TrainingProgram) {
        program.modifiedAt = Date()
        do { try context.save() }
        catch { saveError = error.localizedDescription }
    }

    private func refreshReminder(_ program: TrainingProgram) {
        Task { @MainActor in
            if program.remindersEnabled {
                let reminderOverride = program.rescheduledDate.flatMap {
                    Calendar.current.date(bySettingHour: program.reminderHour, minute: program.reminderMinute, second: 0, of: $0)
                }
                await NotificationService.scheduleProgram(days: program.weekdays, hour: program.reminderHour, minute: program.reminderMinute, override: reminderOverride)
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                reminderMessage = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                    ? nil : "Notifications are off. Enable them in iPhone Settings to receive reminders."
            } else {
                await NotificationService.clearProgram()
                reminderMessage = nil
            }
        }
    }
}
