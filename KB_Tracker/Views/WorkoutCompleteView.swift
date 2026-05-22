// WorkoutCompleteView.swift
// KB_Tracker
//
// Post-workout summary (complete.jsx): hero, 2×2 stat grid, set chart,
// editable notes card, and a primary Save Session button.

import SwiftUI
import SwiftData

struct WorkoutCompleteView: View {
    let session: WorkoutSession
    var onSaveComplete: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var notes: String
    @State private var showDiscardAlert = false

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
                        hero
                        statsGrid
                        SetChart(setTimes: session.setTimes, mode: session.mode)
                        notesCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }

                PrimaryButton(title: "Save Session", action: saveWorkout)
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

            bodyLine
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

    // MARK: - Stats grid

    private var statsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            StatTile(label: "TOTAL", value: mmss(session.totalDuration))
            StatTile(label: "AVG SET", value: mmss(session.averageSetTime ?? 0))
            StatTile(label: "FASTEST", value: mmss(fastest))
            if isEMOM {
                StatTile(label: "OVERTIME", value: "\(overtimeCount)", warn: overtimeCount > 0)
            } else {
                StatTile(label: "SLOWEST", value: mmss(slowest))
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

// MARK: - Helpers

/// Seconds → zero-padded "MM:SS" (matches fmt.mmss in the prototype).
private func mmss(_ sec: TimeInterval) -> String {
    let s = max(0, Int(sec))
    return String(format: "%02d:%02d", s / 60, s % 60)
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
