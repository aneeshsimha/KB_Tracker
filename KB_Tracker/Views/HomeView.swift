// HomeView.swift
// KB_Tracker
//
// Home / workout setup screen. Ported from home.jsx — gravl-style layout
// with big mono numerals as the focal point, supporting controls reduced to
// small text + ± steppers.

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var mode: WorkoutMode = .emom
    @State private var kettlebellType: KBType = .double
    @State private var weight: Int = 20
    @State private var targetMinutes: Int = 20       // EMOM
    @State private var targetRounds: Int = 15        // Rounds mode
    @State private var restDuration: Int = 60        // Rounds mode

    @AppStorage("kb_pref_kbType") private var prefKBType: String = KBType.double.rawValue
    @AppStorage("kb_pref_weight") private var prefWeight: Int = 20

    @State private var route: HomeRoute?
    @State private var showSettings = false
    @State private var workoutType: WorkoutType = .abc
    @State private var targetLadders: Int = 5        // press

    private var lastSession: WorkoutSession? {
        sessions.first(where: { $0.isCompleted })
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Last-session card (or first-time prompt)
                        if let last = lastSession {
                            lastSessionCard(session: last)
                        } else {
                            firstTimeCard
                        }

                        setupBlock
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 20)
                }

                // Footer: start
                PrimaryButton(title: startTitle) {
                    switch workoutType {
                    case .abc:   route = mode == .emom ? .emom : .rounds
                    case .press: route = .press
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
        }
        .navigationDestination(item: $route) { dest in
            switch dest {
            case .emom:
                EMOMTimerView(
                    config: .emom(
                        kettlebellType: kettlebellType,
                        weight: weight,
                        minutes: targetMinutes
                    )
                )
            case .rounds:
                RoundsTimerView(
                    config: .rounds(
                        kettlebellType: kettlebellType,
                        weight: weight,
                        rounds: targetRounds,
                        restSeconds: restDuration
                    )
                )
            case .press:
                PressLadderView(
                    config: .press(
                        kettlebellType: kettlebellType,
                        weight: weight,
                        targetLadders: targetLadders
                    )
                )
            case .history:
                HistoryView()
            }
        }
        .onAppear {
            prefillFromLastSession()
        }
        .onChange(of: mode) { _, newValue in
            // Sync rounds with EMOM minutes when switching to ROUNDS mode
            if newValue == .rounds {
                targetRounds = targetMinutes
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Eyebrow("KB · TRACKER")
            Spacer()
            HStack(spacing: 8) {
                    IconButton(icon: .gear) { showSettings = true }
                    IconButton(icon: .history) { route = .history }
                }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Setup block

    private var setupBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("WORKOUT")
                .padding(.bottom, 8)
            SegmentedToggle(
                options: [
                    SegmentedOption(label: "ABC", value: WorkoutType.abc),
                    SegmentedOption(label: "Press", value: WorkoutType.press),
                ],
                selection: $workoutType
            )
            .padding(.bottom, 22)

            if workoutType == .abc {
                abcSetup
            } else {
                pressSetup
            }
        }
        .padding(.top, 16)
    }

    private var abcSetup: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("MODE").padding(.bottom, 8)
            SegmentedToggle(
                options: [
                    SegmentedOption(label: "EMOM", value: WorkoutMode.emom),
                    SegmentedOption(label: "Rounds", value: WorkoutMode.rounds),
                ],
                selection: $mode
            )
            .padding(.bottom, 22)

            Dial(
                eyebrow: "LOAD",
                value: "\(weight)",
                unit: kettlebellType == .double ? "kg × 2" : "kg",
                onMinus: { stepWeight(-1) },
                onPlus: { stepWeight(+1) }
            ) {
                SegmentedToggle(
                    options: [
                        SegmentedOption(label: "Single", value: KBType.single),
                        SegmentedOption(label: "Double", value: KBType.double),
                    ],
                    selection: $kettlebellType,
                    inline: true
                )
                .padding(.top, 2)
            }

            Spacer().frame(height: 14)
            durationDial
        }
    }

    private var pressSetup: some View {
        VStack(alignment: .leading, spacing: 0) {
            Dial(
                eyebrow: "LADDERS",
                value: "\(targetLadders)",
                unit: "× 2·3·5·10",
                onMinus: { targetLadders = max(WorkoutParameters.laddersMin, targetLadders - 1) },
                onPlus: { targetLadders = min(WorkoutParameters.laddersMax, targetLadders + 1) }
            ) {
                HStack {
                    Text("Total reps")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.ink3)
                    Spacer()
                    Text("\(targetLadders * 20)")
                        .font(AppTypography.mono(12, weight: .regular))
                        .foregroundColor(AppColors.ink3)
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)
                .overlay(alignment: .top) {
                    Rectangle().fill(AppColors.hairline).frame(height: 1)
                }
                .padding(.top, 4)
            }

            Spacer().frame(height: 14)

            Dial(
                eyebrow: "LOAD",
                value: "\(weight)",
                unit: kettlebellType == .double ? "kg × 2" : "kg",
                onMinus: { stepWeight(-1) },
                onPlus: { stepWeight(+1) }
            ) {
                SegmentedToggle(
                    options: [
                        SegmentedOption(label: "Single", value: KBType.single),
                        SegmentedOption(label: "Double", value: KBType.double),
                    ],
                    selection: $kettlebellType,
                    inline: true
                )
                .padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    private var durationDial: some View {
        if mode == .emom {
            Dial(
                eyebrow: "DURATION",
                value: "\(targetMinutes)",
                unit: "min",
                onMinus: { stepDuration(-1) },
                onPlus: { stepDuration(+1) }
            ) {
                HStack {
                    Text("Total work")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.ink3)
                    Spacer()
                    Text((targetMinutes * 60).formattedMinutesSecondsPadded)
                        .font(AppTypography.mono(12, weight: .regular))
                        .foregroundColor(AppColors.ink3)
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppColors.hairline)
                        .frame(height: 1)
                }
                .padding(.top, 4)
            }
        } else {
            Dial(
                eyebrow: "ROUNDS",
                value: "\(targetRounds)",
                unit: "rds",
                onMinus: { stepDuration(-1) },
                onPlus: { stepDuration(+1) }
            ) {
                HStack {
                    Eyebrow("REST")
                    Spacer()
                    HStack(spacing: 10) {
                        StepperButton(icon: .minus) { stepRest(-1) }
                        Text(restDuration.formattedMinutesSecondsPadded)
                            .font(AppTypography.mono(17, weight: .bold))
                            .foregroundColor(AppColors.ink)
                            .frame(minWidth: 56)
                            .multilineTextAlignment(.center)
                        StepperButton(icon: .plus) { stepRest(+1) }
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppColors.hairline)
                        .frame(height: 1)
                }
                .padding(.top, 4)
            }
        }
    }

    private var startTitle: String {
        switch workoutType {
        case .abc:   return mode == .emom ? "Start · \(targetMinutes) min" : "Start · \(targetRounds) rounds"
        case .press: return "Start · \(targetLadders) ladders"
        }
    }

    // MARK: - Last-session card

    private func lastSessionCard(session: WorkoutSession) -> some View {
        Button {
            route = .history
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Eyebrow("LAST SESSION · \(relativeDay(session.date).uppercased())")
                    Spacer()
                    Image(systemName: KBIcon.chevron.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColors.ink4)
                }
                .padding(.bottom, 10)

                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(session.completedRounds)")
                            .font(AppTypography.mono(38, weight: .bold))
                            .foregroundColor(AppColors.ink)
                        Text("/\(session.mode == .emom ? session.targetMinutes : session.targetRounds)")
                            .font(AppTypography.mono(38, weight: .medium))
                            .foregroundColor(AppColors.ink3)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(session.mode == .emom ? "EMOM" : "Rounds") · \(session.weightDisplay)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.ink)
                        Text("\(Int(session.totalDuration).formattedMinutesSecondsPadded) total")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.ink3)
                    }
                }

                if !session.setTimes.isEmpty {
                    SparkBars(times: session.setTimes, mode: session.mode)
                        .padding(.top, 12)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .kbCard()
        }
        .buttonStyle(TapScaleStyle())
    }

    // MARK: - First-time card

    private var firstTimeCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.surface2)
                    .overlay(Circle().stroke(AppColors.hairline, lineWidth: 1))
                KettlebellGlyph(size: 26)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Eyebrow("FIRST SESSION")
                Text("Pick your kit, your clock, your target. Then move.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.ink2)
                    .lineSpacing(14 * 0.35)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kbCard()
    }

    // MARK: - Steppers

    private func stepWeight(_ d: Int) {
        weight = max(WorkoutParameters.weightMin, min(WorkoutParameters.weightMax, weight + d * WorkoutParameters.weightStep))
    }

    private func stepDuration(_ d: Int) {
        if mode == .emom {
            targetMinutes = max(WorkoutParameters.emomMinutesMin, min(WorkoutParameters.emomMinutesMax, targetMinutes + d))
        } else {
            targetRounds = max(WorkoutParameters.roundsMin, min(WorkoutParameters.roundsMax, targetRounds + d))
        }
    }

    private func stepRest(_ d: Int) {
        restDuration = max(WorkoutParameters.restMin, min(WorkoutParameters.restMax, restDuration + d * WorkoutParameters.restStep))
    }

    // MARK: - Prefill logic

    private func prefillFromLastSession() {
        let setup = HomeSetupLogic.initialKBSetup(
            lastSession: lastSession,
            prefKBType: prefKBType,
            prefWeight: prefWeight
        )
        kettlebellType = setup.kbType
        weight = setup.weight

        guard let last = lastSession else { return }
        mode = last.mode
        if last.mode == .emom {
            targetMinutes = last.targetMinutes
        } else {
            targetRounds = last.targetRounds
            restDuration = last.restDuration ?? 60
        }
    }
}

// MARK: - Navigation route

fileprivate enum HomeRoute: Hashable, Identifiable {
    case emom
    case rounds
    case press
    case history

    var id: Self { self }
}

// MARK: - Formatting helpers

/// Relative day string (Today / Yesterday / N days ago …), from home.jsx fmt.relativeDay.
fileprivate func relativeDay(_ date: Date) -> String {
    let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    if days <= 0 { return "Today" }
    if days == 1 { return "Yesterday" }
    if days < 7 { return "\(days) days ago" }
    if days < 14 { return "Last week" }
    return "\(days / 7) weeks ago"
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
