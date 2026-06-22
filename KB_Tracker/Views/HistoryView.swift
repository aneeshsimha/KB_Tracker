// HistoryView.swift
// KB_Tracker
//
// List of past sessions (history.jsx): top stat tiles, 8-week training-arc
// heatmap, and sessions grouped by relative week. Each row taps into detail.

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Environment(\.dismiss) private var dismiss

    // MARK: - Derived totals

    private var totalSessions: Int { sessions.count }
    private var totalRounds: Int { sessions.reduce(0) { $0 + $1.completedRounds } }
    private var totalHours: Double { sessions.reduce(0.0) { $0 + $1.totalDuration } / 3600 }

    private var groups: [WeekGroup] { groupByWeek(sessions) }
    private var exportCSV: String { WorkoutExporter.csv(from: sessions) }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // top stats
                        HStack(spacing: 8) {
                            Mini(label: "SESSIONS", value: "\(totalSessions)")
                            Mini(label: "ROUNDS", value: "\(totalRounds)")
                            Mini(label: "HOURS", value: String(format: "%.1f", totalHours))
                        }
                        .padding(.bottom, 18)

                        // 8-week training arc heatmap
                        WeekStrip(sessions: sessions)

                        if totalSessions == 0 {
                            VStack(spacing: 10) {
                                Eyebrow("NO SESSIONS YET")
                                Text("Finish a workout and it'll land here.")
                                    .font(AppTypography.bodyText)
                                    .foregroundColor(AppColors.ink2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }

                        // grouped list
                        ForEach(groups) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Eyebrow(group.label)
                                    Spacer()
                                    Eyebrow("\(group.items.count) ×", color: AppColors.ink4)
                                }
                                VStack(spacing: 8) {
                                    ForEach(group.items) { session in
                                        NavigationLink {
                                            HistoryDetailView(session: session)
                                        } label: {
                                            SessionRow(session: session)
                                        }
                                        .buttonStyle(TapScaleStyle())
                                    }
                                }
                            }
                            .padding(.top, 22)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            IconButton(icon: .back) { dismiss() }
            Spacer()
            Eyebrow("HISTORY")
            Spacer()
            ShareLink(
                item: exportCSV,
                preview: SharePreview("KB Tracker Sessions", image: Image(systemName: "figure.strengthtraining.traditional"))
            ) {
                Image(systemName: KBIcon.share.rawValue)
                    .font(.system(size: 32 * 0.42, weight: .semibold))
                    .foregroundColor(AppColors.ink)
                    .frame(width: 32, height: 32)
                    .background(AppColors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppColors.hairline, lineWidth: 1))
            }
            .buttonStyle(TapScaleStyle())
            .disabled(sessions.isEmpty)
        }
        .frame(height: 32)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }
}

// MARK: - Mini stat tile

/// Small stat tile (history.jsx Mini): eyebrow label + 24pt mono value.
fileprivate struct Mini: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(label, size: 10)
            Text(value)
                .font(AppTypography.mono(24))
                .kerning(-0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kbCard()
    }
}

// MARK: - Week strip (8-week heatmap)

/// 8-week training-arc heatmap (history.jsx WeekStrip): 56 day cells colored
/// by session count, oldest week (W1) left → most recent (W8) right.
fileprivate struct WeekStrip: View {
    let sessions: [WorkoutSession]

    private var buckets: [Int] { weekStripBuckets(sessions) }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 8)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Eyebrow("8 WEEK ARC")
                Spacer()
                Eyebrow("RECENT →", color: AppColors.ink4)
            }
            .padding(.bottom, 10)

            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(buckets.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(cellColor(buckets[i]))
                        .frame(height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(AppColors.hairline, lineWidth: 1)
                        )
                }
            }
            .padding(.bottom, 8)

            HStack {
                ForEach(1...8, id: \.self) { w in
                    Text("W\(w)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(AppColors.ink4)
                    if w < 8 { Spacer() }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kbCard()
    }

    private func cellColor(_ count: Int) -> Color {
        switch count {
        case 0: return AppColors.surface2
        case 1: return Color.white.opacity(0.4)
        default: return AppColors.ink
        }
    }
}

// MARK: - Session row

/// One past session (history.jsx SessionRow): date block, mode + weight,
/// completed/target · duration, a micro spark chart, and a chevron.
fileprivate struct SessionRow: View {
    let session: WorkoutSession

    private var weightPhrase: String {
        session.kettlebellType == .double ? "2×\(session.weight)kg" : "\(session.weight)kg"
    }

    private var workoutTitle: String {
        switch session.workoutType {
        case .abc:          return session.mode == .emom ? "EMOM" : "Rounds"
        case .snatchTest:   return "Snatch Test"
        case .swingInterval: return "Swing Interval"
        case .press:        return "Press"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // date block
            VStack(spacing: 2) {
                Text(dayOfMonth(session.date))
                    .font(AppTypography.mono(22))
                Eyebrow(shortMonth(session.date), size: 9)
            }
            .frame(width: 36)
            .padding(.trailing, 14)
            .overlay(alignment: .trailing) {
                Rectangle().fill(AppColors.hairline).frame(width: 1)
            }

            // main
            if session.workoutType == .press {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("Press")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.ink)
                        Text(session.weightDisplay)
                            .font(AppTypography.mono(13, weight: .semibold))
                            .foregroundColor(AppColors.ink3)
                    }
                    HStack(spacing: 0) {
                        Text("\(session.totalReps)")
                            .font(AppTypography.mono(12.5, weight: .semibold))
                            .foregroundColor(AppColors.ink2)
                        Text(" reps")
                            .font(.system(size: 12.5))
                            .foregroundColor(AppColors.ink4)
                        Text("  ·  ")
                            .font(.system(size: 12.5))
                            .foregroundColor(AppColors.ink4)
                        Text("\(session.completedLadders) ladders")
                            .font(AppTypography.mono(12.5, weight: .regular))
                            .foregroundColor(AppColors.ink2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(workoutTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.ink)
                        Text(weightPhrase)
                            .font(AppTypography.mono(13, weight: .semibold))
                            .foregroundColor(AppColors.ink3)
                    }
                    HStack(spacing: 0) {
                        Text("\(session.completedRounds)")
                            .font(AppTypography.mono(12.5, weight: .semibold))
                            .foregroundColor(AppColors.ink2)
                        Text("/\(session.mode == .emom ? session.targetMinutes : session.targetRounds)")
                            .font(.system(size: 12.5))
                            .foregroundColor(AppColors.ink4)
                        Text("  ·  ")
                            .font(.system(size: 12.5))
                            .foregroundColor(AppColors.ink4)
                        Text(session.totalDuration.formattedMinutesSecondsPadded)
                            .font(AppTypography.mono(12.5, weight: .regular))
                            .foregroundColor(AppColors.ink2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // micro spark
            if session.workoutType == .press {
                if !session.ladderReps.isEmpty {
                    SparkBars(times: session.ladderReps.map { TimeInterval($0) },
                              mode: .rounds,
                              height: 20,
                              limit: 20)
                        .frame(width: 60)
                }
            } else {
                if !session.setTimes.isEmpty {
                    SparkBars(times: session.setTimes,
                              mode: session.mode,
                              height: 20,
                              limit: 20)
                        .frame(width: 60)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.ink4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kbCard()
    }
}

// MARK: - Grouping / formatting helpers

/// One relative-week bucket of sessions ("THIS WEEK", "LAST WEEK", "N WEEKS AGO").
fileprivate struct WeekGroup: Identifiable {
    let id: Int            // weeks-ago index
    let label: String
    var items: [WorkoutSession]
}

/// Group sessions (newest first) by whole weeks elapsed since today.
fileprivate func groupByWeek(_ sessions: [WorkoutSession]) -> [WeekGroup] {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let sorted = sessions.sorted { $0.date > $1.date }

    var groups: [WeekGroup] = []
    for s in sorted {
        let day = cal.startOfDay(for: s.date)
        let days = cal.dateComponents([.day], from: day, to: today).day ?? 0
        let wk = max(0, days / 7)
        let label = wk == 0 ? "THIS WEEK" : wk == 1 ? "LAST WEEK" : "\(wk) WEEKS AGO"
        if let idx = groups.lastIndex(where: { $0.id == wk }) {
            groups[idx].items.append(s)
        } else {
            groups.append(WeekGroup(id: wk, label: label, items: [s]))
        }
    }
    return groups
}

/// 56-day counts (oldest → newest) for the 8-week heatmap.
fileprivate func weekStripBuckets(_ sessions: [WorkoutSession]) -> [Int] {
    let days = 56
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    var buckets = Array(repeating: 0, count: days)
    for s in sessions {
        let day = cal.startOfDay(for: s.date)
        let diff = cal.dateComponents([.day], from: day, to: today).day ?? -1
        if diff >= 0 && diff < days {
            buckets[days - 1 - diff] += 1
        }
    }
    return buckets
}

fileprivate func dayOfMonth(_ date: Date) -> String {
    "\(Calendar.current.component(.day, from: date))"
}

fileprivate func shortMonth(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "MMM"
    return f.string(from: date)
}

#Preview {
    let config = WorkoutSession(mode: .emom, kettlebellType: .double, weight: 20, targetRounds: 20)
    config.completedRounds = 18
    config.totalDuration = 1140
    config.setTimes = [42, 45, 48, 51, 44, 47, 62, 55, 43, 46]

    return NavigationStack {
        HistoryView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
