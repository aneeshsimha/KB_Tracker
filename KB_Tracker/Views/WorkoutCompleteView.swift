// WorkoutCompleteView.swift
// KB_Tracker
//
// Post-workout summary (complete.jsx): hero, 2×2 stat grid, set chart,
// editable notes card, and a primary Save Session button.

import HealthKit
import SwiftUI
import SwiftData

struct WorkoutCompleteView: View {
    let session: WorkoutSession
    var onSaveComplete: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var notes: String
    @State private var showDiscardAlert = false
    @State private var healthSaveState: HealthSaveState = .idle

    private enum HealthSaveState { case idle, saving, saved, failed }

    init(session: WorkoutSession, onSaveComplete: (() -> Void)? = nil) {
        self.session = session
        self.onSaveComplete = onSaveComplete
        _notes = State(initialValue: session.notes ?? "")
    }

    // MARK: - Derived stats

    private var times: [TimeInterval] { session.setTimes }
    private var isEMOM: Bool { session.mode == .emom }

    private var fastest: TimeInterval { times.min() ?? 0 }
    private var slowest: TimeInterval { times.max() ?? 0 }
    private var overtimeCount: Int { isEMOM ? times.filter { $0 > 60 }.count : 0 }

    private var weightPhrase: String {
        session.kettlebellType == .double ? "2×\(session.weight)kg" : "\(session.weight)kg"
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if session.workoutType == .press {
                            pressHero
                            pressStatsGrid
                            pressLadderChart
                        } else {
                            hero
                            statsGrid
                            SetChart(setTimes: session.setTimes, mode: session.mode)
                        }
                        notesCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }

                VStack(spacing: 10) {
                    PrimaryButton(title: "Save Session", action: saveWorkout)
                    if HealthKitService.isAvailable {
                        healthButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .interactiveDismissDisabled()
        .alert("Discard Workout?", isPresented: $showDiscardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Discard", role: .destructive) { dismiss() }
        } message: {
            Text("This workout will not be saved.")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: { showDiscardAlert = true }) {
                Text("Discard")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.ink3)
            }
            .buttonStyle(TapScaleStyle())

            Spacer()

            Eyebrow("SESSION · \(session.date.kbDateShort.uppercased())")

            Spacer()

            Color.clear.frame(width: 60, height: 1)
        }
        .frame(height: 32)
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("✓ COMPLETE", color: AppColors.green)
                .padding(.bottom, 8)

            (
                Text("\(session.completedRounds) \(isEMOM ? "minutes" : "rounds")\n")
                    .foregroundColor(AppColors.ink)
                + Text("at \(weightPhrase).")
                    .foregroundColor(AppColors.ink3)
            )
            .font(.system(size: 36, weight: .heavy))
            .kerning(-0.8)
            .lineSpacing(2)
            .padding(.bottom, 10)

            switch session.workoutType {
            case .abc:           bodyLine
            case .snatchTest:    snatchBodyLine
            case .swingInterval: swingBodyLine
            case .press:         EmptyView()
            }
        }
        .padding(.vertical, 6)
    }

    private var bodyLine: some View {
        let mono = AppTypography.mono(15)
        let ink2 = AppColors.ink2
        let ink = AppColors.ink
        let cleans = session.completedRounds * 2
        let presses = session.completedRounds
        let squats = session.completedRounds * 3

        let tLead: Text = Text("That's ").foregroundColor(ink2)
        let tCleans: Text = Text("\(cleans)").font(mono).foregroundColor(ink)
        let tCleansLabel: Text = Text(" cleans, ").foregroundColor(ink2)
        let tPresses: Text = Text("\(presses)").font(mono).foregroundColor(ink)
        let tPressesLabel: Text = Text(" presses, ").foregroundColor(ink2)
        let tSquats: Text = Text("\(squats)").font(mono).foregroundColor(ink)
        let tSquatsLabel: Text = Text(" front squats.").foregroundColor(ink2)

        return (tLead + tCleans + tCleansLabel + tPresses + tPressesLabel + tSquats + tSquatsLabel)
            .font(AppTypography.bodyText)
    }

    private var snatchBodyLine: some View {
        Text("That's \(session.completedRounds * 20) snatches.")
            .font(AppTypography.bodyText)
            .foregroundColor(AppColors.ink2)
    }

    private var swingBodyLine: some View {
        Text("That's \(session.completedRounds) sets of swings.")
            .font(AppTypography.bodyText)
            .foregroundColor(AppColors.ink2)
    }

    // MARK: - Press hero

    private var pressHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("✓ COMPLETE", color: AppColors.green)
                .padding(.bottom, 8)
            (
                Text("\(session.totalReps) presses\n").foregroundColor(AppColors.ink)
                + Text("at \(weightPhrase).").foregroundColor(AppColors.ink3)
            )
            .font(.system(size: 36, weight: .heavy))
            .kerning(-0.8)
            .lineSpacing(2)
            .padding(.bottom, 10)

            Text("\(session.completedLadders) ladders of 2·3·5·10.")
                .font(AppTypography.bodyText)
                .foregroundColor(AppColors.ink2)
        }
        .padding(.vertical, 6)
    }

    private var pressStatsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        let avgLadder = session.completedLadders > 0
            ? session.totalDuration / Double(session.completedLadders) : 0
        return LazyVGrid(columns: columns, spacing: 10) {
            StatTile(label: "TOTAL REPS", value: "\(session.totalReps)")
            StatTile(label: "LADDERS", value: "\(session.completedLadders)/\(session.targetLadders)")
            StatTile(label: "TIME", value: session.totalDuration.formattedMinutesSecondsPadded)
            StatTile(label: "AVG · LADDER", value: avgLadder.formattedMinutesSecondsPadded)
        }
    }

    private var pressLadderChart: some View {
        KBCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Eyebrow("LADDER BREAKDOWN")
                    Spacer()
                    Eyebrow("\(session.ladderReps.count) LDR", color: AppColors.ink4)
                }
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(session.ladderReps.enumerated()), id: \.offset) { _, reps in
                        let h = max(4, CGFloat(reps) / 20.0 * 110)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(reps == 20 ? AppColors.ink : AppColors.ink3)
                            .frame(maxWidth: .infinity)
                            .frame(height: h)
                    }
                }
                .frame(height: 110, alignment: .bottom)
            }
        }
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            StatTile(label: "TOTAL", value: session.totalDuration.formattedMinutesSecondsPadded)
            StatTile(label: "AVG SET", value: (session.averageSetTime ?? 0).formattedMinutesSecondsPadded)
            StatTile(label: "FASTEST", value: fastest.formattedMinutesSecondsPadded)
            if isEMOM {
                StatTile(label: "OVERTIME", value: "\(overtimeCount)", warn: overtimeCount > 0)
            } else {
                StatTile(label: "SLOWEST", value: slowest.formattedMinutesSecondsPadded)
            }
        }
    }

    // MARK: - Notes

    private var notesCard: some View {
        KBCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("NOTES")
                TextField(
                    "How did it feel? Form notes, soreness, etc.",
                    text: $notes,
                    axis: .vertical
                )
                .font(.system(size: 15))
                .foregroundColor(AppColors.ink)
                .lineLimit(3...)
                .tint(AppColors.ink)
            }
        }
    }

    // MARK: - Health button

    private var healthButton: some View {
        Button {
            Task {
                healthSaveState = .saving
                let ok = await HealthKitService.save(session)
                healthSaveState = ok ? .saved : .failed
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: healthSaveState == .saved ? "checkmark" : "heart.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(healthButtonLabel)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(healthSaveState == .saved ? AppColors.green : AppColors.ink3)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(TapScaleStyle())
        .disabled(healthSaveState == .saving || healthSaveState == .saved)
    }

    private var healthButtonLabel: String {
        switch healthSaveState {
        case .idle:   return "Save to Apple Health"
        case .saving: return "Saving…"
        case .saved:  return "Saved to Health"
        case .failed: return "Health unavailable"
        }
    }

    // MARK: - Actions

    private func saveWorkout() {
        session.notes = notes.isEmpty ? nil : notes
        session.isCompleted = true
        modelContext.insert(session)

        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onSaveComplete?()
        }
    }
}

private extension Date {
    /// Short date "MMM d" (e.g. "May 22"), used uppercased in the eyebrow.
    var kbDateShort: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: self)
    }
}

#Preview {
    let session = WorkoutSession(
        mode: .emom,
        kettlebellType: .double,
        weight: 20,
        targetRounds: 20,
        restDuration: nil
    )
    session.completedRounds = 18
    session.totalDuration = 1140
    session.setTimes = [42, 45, 48, 51, 44, 47, 62, 55, 43, 46, 49, 52, 44, 47, 50, 53, 45, 48]

    return NavigationStack {
        WorkoutCompleteView(session: session)
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
