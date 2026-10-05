import Foundation

enum ProgramService {
    static func plannedDates(program: TrainingProgram, inWeekStarting start: Date, calendar: Calendar = .current) -> [Date] {
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
        var dates = (0..<7).compactMap { offset -> Date? in
            guard program.weekdays.contains(offset + 1) else { return nil }
            return calendar.date(byAdding: .day, value: offset, to: start)
        }
        for change in program.rescheduleHistory {
            dates.removeAll { calendar.isDate($0, inSameDayAs: change.plannedDate) }
            if change.movedDate >= start && change.movedDate < end,
               !dates.contains(where: { calendar.isDate($0, inSameDayAs: change.movedDate) }) {
                dates.append(calendar.startOfDay(for: change.movedDate))
            }
        }
        return dates.sorted()
    }

    static func nextDefinition(program: TrainingProgram) -> WorkoutDefinition {
        if let override = program.nextOverride, override.validationError == nil { return override }
        let templates = program.templateDefinitions.filter { $0.validationError == nil }
        if program.usesTemplates, !templates.isEmpty {
            return templates[max(0, program.nextIndex) % templates.count]
        }
        return builtInDefinition(program: program, type: max(0, program.nextIndex).isMultiple(of: 2) ? .abc : .press)
    }

    static func builtInDefinition(program: TrainingProgram, type: WorkoutType) -> WorkoutDefinition {
        if type == .abc {
            var block = WorkoutBlock(name: "ABC complex", kind: program.abcMode == .emom ? .emom : .rounds)
            block.movements = [.init(name: "Clean", reps: 2), .init(name: "Press", reps: 1), .init(name: "Front squat", reps: 3)]
            block.loadKg = program.abcWeightKg
            block.bells = program.abcBells
            block.rounds = program.abcMode == .emom ? program.abcMinutes : program.abcRounds
            block.restSeconds = program.abcRestSeconds
            return WorkoutDefinition(name: "ABC", workoutType: .abc, blocks: [block])
        }
        var block = WorkoutBlock(name: "Press ladder", kind: .ladder)
        block.movements = [.init(name: "Press")]
        block.loadKg = program.pressWeightKg
        block.bells = program.pressBells
        block.rounds = program.pressLadders
        return WorkoutDefinition(name: "Press", workoutType: .press, blocks: [block])
    }

    /// Evaluates a finished program session once. Missing ratings never alter the prescription.
    static func evaluate(session: WorkoutSession, program: TrainingProgram) {
        guard session.programID == program.id, !program.evaluatedSessionIDs.contains(session.id) else { return }
        guard session.endedAt != nil || session.isCompleted else {
            return
        }
        program.evaluatedSessionIDs.append(session.id)
        program.modifiedAt = Date()
        defer { recordDecision(program: program, sessionID: session.id) }
        let prescribed = session.definition
        let target = prescribed?.workoutType ?? session.workoutType
        let wasOverride = program.nextOverride != nil
        if session.isCompleted {
            program.nextIndex += 1
            program.nextOverride = nil
            program.rescheduledDate = nil
        }
        guard !program.usesTemplates, !wasOverride, (target == .abc || target == .press), program.autoProgress else {
            clearStreaks(target: target, program: program)
            program.lastDecision = program.usesTemplates ? "Template completed. Progression is manual." : "Progression is paused."
            return
        }
        let targetKey = target.rawValue
        program.streakTargetRaw = targetKey
        let prescriptionKey = prescribed.map { Self.prescriptionKey($0) } ?? "\(session.mode.rawValue):\(session.weight):\(session.targetRounds):\(session.targetLadders)"
        if target == .press {
            if program.pressStreakKey != prescriptionKey { clearStreaks(target: target, program: program); program.pressStreakKey = prescriptionKey }
        } else if program.abcStreakKey != prescriptionKey {
            clearStreaks(target: target, program: program)
            program.abcStreakKey = prescriptionKey
        }
        if !session.isCompleted || session.difficulty == .hard {
            let count = target == .press ? program.pressStruggleStreak + 1 : program.abcStruggleStreak + 1
            if target == .press { program.pressStruggleStreak = count; program.pressSuccessStreak = 0 }
            else { program.abcStruggleStreak = count; program.abcSuccessStreak = 0 }
            if count >= 2 {
                reduce(target: target, program: program)
                clearStreaks(target: target, program: program)
            } else {
                program.lastDecision = "One hard or incomplete session. Repeat this target."
            }
        } else if session.difficulty == .easy || session.difficulty == .manageable {
            let count = target == .press ? program.pressSuccessStreak + 1 : program.abcSuccessStreak + 1
            if target == .press { program.pressSuccessStreak = count; program.pressStruggleStreak = 0 }
            else { program.abcSuccessStreak = count; program.abcStruggleStreak = 0 }
            if count >= 2 {
                advance(target: target, program: program)
                clearStreaks(target: target, program: program)
            } else {
                program.lastDecision = "One successful session. Repeat this target."
            }
        } else {
            clearStreaks(target: target, program: program)
            program.lastDecision = "Add a difficulty rating to guide progression. Target held."
        }
    }

    private static func clearStreaks(target: WorkoutType, program: TrainingProgram) {
        if target == .press { program.pressSuccessStreak = 0; program.pressStruggleStreak = 0 }
        if target == .abc { program.abcSuccessStreak = 0; program.abcStruggleStreak = 0 }
    }

    static func prescriptionKey(_ definition: WorkoutDefinition) -> String {
        definition.blocks.map { block in
            let movements = block.movements.map { movement in
                let name = movement.name.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ").lowercased()
                return "\(name):\(movement.reps.map(String.init) ?? "?"):\(movement.perSide)"
            }.joined(separator: ";")
            return "\(block.kind.rawValue):\(block.loadKg):\(block.bells):\(block.rounds):\(block.workSeconds):\(block.restSeconds):\(block.rungs):\(movements)"
        }.joined(separator: "|")
    }

    static func approveNextBell(program: TrainingProgram, weightKg: Double) {
        guard weightKg.isFinite, weightKg > 0, weightKg <= 500, program.pendingBellApproval else { return }
        let currentWeight = program.pendingBellTargetRaw == WorkoutType.press.rawValue ? program.pressWeightKg : program.abcWeightKg
        guard weightKg > currentWeight else { return }
        if program.pendingBellTargetRaw == WorkoutType.press.rawValue {
            program.pressWeightKg = weightKg
            program.pressLadders = max(1, min(10, program.pressStartLadders))
        } else {
            program.abcWeightKg = weightKg
            if program.abcMode == .emom { program.abcMinutes = max(1, min(30, program.abcStartMinutes)) }
            else { program.abcRounds = max(1, min(20, program.abcStartRounds)) }
        }
        program.pendingBellApproval = false
        program.pendingBellTargetRaw = ""
        program.lastDecision = "New bell approved. Returning to the configured starting target."
        program.modifiedAt = Date()
        recordDecision(program: program, sessionID: nil)
    }

    private static func recordDecision(program: TrainingProgram, sessionID: UUID?) {
        var history = program.decisionHistory
        history.append(ProgramDecision(sessionID: sessionID, message: program.lastDecision))
        program.decisionHistory = history
    }

    private static func advance(target: WorkoutType, program: TrainingProgram) {
        if target == .press {
            if program.pressLadders >= 10 {
                program.pendingBellApproval = true
                program.pendingBellTargetRaw = target.rawValue
                program.lastDecision = "10 ladders reached. Choose the next bell when ready."
            } else {
                program.pressLadders += 1
                program.lastDecision = "Two successful press sessions. Added one ladder."
            }
        } else if program.abcMode == .emom {
            if program.abcMinutes >= 30 {
                program.pendingBellApproval = true
                program.pendingBellTargetRaw = target.rawValue
                program.lastDecision = "30 minutes reached. Choose the next bell when ready."
            } else {
                program.abcMinutes += 1
                program.lastDecision = "Two successful ABC sessions. Added one minute."
            }
        } else if program.abcRounds >= 20 {
            program.pendingBellApproval = true
            program.pendingBellTargetRaw = target.rawValue
            program.lastDecision = "20 rounds reached. Choose the next bell when ready."
        } else {
            program.abcRounds += 1
            program.lastDecision = "Two successful ABC sessions. Added one round."
        }
    }

    private static func reduce(target: WorkoutType, program: TrainingProgram) {
        if program.pendingBellTargetRaw == target.rawValue {
            program.pendingBellApproval = false
            program.pendingBellTargetRaw = ""
        }
        if target == .press {
            let old = program.pressLadders
            program.pressLadders = max(1, Int((Double(old) * 0.8).rounded(.down)))
            program.lastDecision = "Two hard or incomplete press sessions. Reduced \(old) to \(program.pressLadders) ladders."
        } else if program.abcMode == .emom {
            let old = program.abcMinutes
            program.abcMinutes = max(1, Int((Double(old) * 0.8).rounded(.down)))
            program.lastDecision = "Two hard or incomplete ABC sessions. Reduced \(old) to \(program.abcMinutes) minutes."
        } else {
            let old = program.abcRounds
            program.abcRounds = max(1, Int((Double(old) * 0.8).rounded(.down)))
            program.lastDecision = "Two hard or incomplete ABC sessions. Reduced \(old) to \(program.abcRounds) rounds."
        }
    }
}
