// HistoryDetailView.swift
// KB_Tracker
//
// Expanded view of a single past session (history.jsx HistoryDetail):
// hero, 2×2 stat grid, set chart, per-set tiles, editable notes, delete.

import SwiftUI
import SwiftData

struct HistoryDetailView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var notes: String
    @State private var showDeleteConfirm = false

    init(session: WorkoutSession) {
        self.session = session
        _notes = State(initialValue: session.notes ?? "")
    }

    // MARK: - Derived stats

    private var times: [TimeInterval] { session.setTimes }
    private var isEMOM: Bool { session.mode == .emom }

    private var fastest: TimeInterval { times.min() ?? 0 }
    private var slowest: TimeInterval { times.max() ?? 0 }
    private var avg: TimeInterval { session.averageSetTime ?? 0 }
    private var overtimeCount: Int { isEMOM ? times.filter { $0 > 60 }.count : 0 }

    private var weightPhrase: String {
        session.kettlebellType == .double ? "2×\(session.weight)KG" : "\(session.weight)KG"
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if session.workoutType == .press {
                            pressHero
                            pressStatsGrid
                            pressLadderGrid
                        } else {
                            hero
                            statsGrid
                            SetChart(setTimes: session.setTimes, mode: session.mode)
                            eachSetCard
                        }
                        notesCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .confirmSheet(isPresented: $showDeleteConfirm,
                      title: "Delete this session?",
                      message: "This can't be undone.",
                      confirmLabel: "Delete",
                      cancelLabel: "Cancel") {
            modelContext.delete(session)
            dismiss()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            IconButton(icon: .back) { commitNotes(); dismiss() }
            Spacer()
            Eyebrow(fullDate(session.date).uppercased())
            Spacer()
            IconButton(icon: .trash, color: AppColors.red) { showDeleteConfirm = true }
        }
        .frame(height: 32)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            (
                Text("\(session.completedRounds)")
                    .foregroundColor(AppColors.ink)
                + Text("/\(session.targetRounds)")
                    .foregroundColor(AppColors.ink3)
            )
            .font(AppTypography.numeralLg)
            .kerning(-1.5)

            (
                Text(isEMOM ? "EMOM · MINUTES" : "ROUNDS COMPLETED")
                    .foregroundColor(AppColors.ink3)
                + Text(" · \(weightPhrase)")
                    .foregroundColor(AppColors.ink4)
            )
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .kerning(11 * 0.18)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        return LazyVGrid(columns: columns, spacing: 8) {
            StatTile(label: "TOTAL", value: mmssDetail(session.totalDuration))
            StatTile(label: "AVG SET", value: mmssDetail(avg))
            StatTile(label: "FASTEST", value: mmssDetail(fastest))
            if isEMOM {
                StatTile(label: "OVERTIME", value: "\(overtimeCount)", warn: overtimeCount > 0)
            } else {
                StatTile(label: "SLOWEST", value: mmssDetail(slowest))
            }
        }
    }

    // MARK: - Each set card

    private var eachSetCard: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)
        return KBCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("EACH SET")
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Array(times.enumerated()), id: \.offset) { index, t in
                        SetCell(index: index, time: t, isEMOM: isEMOM)
                    }
                }
            }
        }
    }

    // MARK: - Press hero

    private var pressHero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(session.totalReps)")
                .font(AppTypography.numeralLg)
                .kerning(-1.5)
                .foregroundColor(AppColors.ink)

            let eyebrowLabel = Text("PRESS · REPS")
                .foregroundColor(AppColors.ink3)
            let eyebrowWeight = Text(" · \(weightPhrase)")
                .foregroundColor(AppColors.ink4)
            (eyebrowLabel + eyebrowWeight)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .kerning(11 * 0.18)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Press stats grid

    private var pressStatsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        let avgLadder = session.totalDuration / Double(max(1, session.completedLadders))
        return LazyVGrid(columns: columns, spacing: 8) {
            StatTile(label: "TOTAL REPS", value: "\(session.totalReps)")
            StatTile(label: "LADDERS", value: "\(session.completedLadders)/\(session.targetLadders)")
            StatTile(label: "TIME", value: mmssDetail(session.totalDuration))
            StatTile(label: "AVG · LADDER", value: mmssDetail(avgLadder))
        }
    }

    // MARK: - Press ladder grid

    private var pressLadderGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)
        return KBCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("EACH LADDER")
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Array(session.ladderReps.enumerated()), id: \.offset) { i, reps in
                        VStack(spacing: 2) {
                            Eyebrow(String(format: "L%02d", i + 1), size: 9)
                            Text("\(reps)")
                                .font(AppTypography.mono(13))
                                .foregroundColor(AppColors.ink)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 8)
                        .background(AppColors.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppColors.hairline, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Notes

    private var notesCard: some View {
        KBCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("NOTES")
                TextField("Add notes…", text: $notes, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.ink)
                    .lineLimit(3...)
                    .tint(AppColors.ink)
                    .onChange(of: notes) { commitNotes() }
            }
        }
    }

    // MARK: - Actions

    private func commitNotes() {
        let trimmed = notes.isEmpty ? nil : notes
        if session.notes != trimmed {
            session.notes = trimmed
        }
    }
}

// MARK: - Per-set tile

/// One per-set tile (history.jsx EACH SET cell): "M01"/"R01" eyebrow + mm:ss,
/// red when EMOM and over 60s.
fileprivate struct SetCell: View {
    let index: Int
    let time: TimeInterval
    let isEMOM: Bool

    private var over: Bool { isEMOM && time > 60 }

    var body: some View {
        VStack(spacing: 2) {
            Eyebrow("\(isEMOM ? "M" : "R")\(String(format: "%02d", index + 1))", size: 9)
            Text(mmssDetail(time))
                .font(AppTypography.mono(13))
                .foregroundColor(over ? AppColors.red : AppColors.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(AppColors.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColors.hairline, lineWidth: 1)
        )
    }
}

// MARK: - Formatting helpers

/// Seconds → zero-padded "MM:SS".
fileprivate func mmssDetail(_ sec: TimeInterval) -> String {
    let s = max(0, Int(sec))
    return String(format: "%02d:%02d", s / 60, s % 60)
}

/// Full date "EEE, MMM d" (e.g. "Fri, May 22"), used uppercased in the header.
fileprivate func fullDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "EEE, MMM d"
    return f.string(from: date)
}

#Preview {
    let sampleSession = WorkoutSession(
        mode: .emom,
        kettlebellType: .double,
        weight: 20,
        targetRounds: 20
    )
    sampleSession.setTimes = [42, 45, 48, 51, 55, 58, 62, 65, 48, 52]
    sampleSession.completedRounds = 10
    sampleSession.totalDuration = 600
    sampleSession.notes = "Grip started failing on round 7"

    return NavigationStack {
        HistoryDetailView(session: sampleSession)
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
