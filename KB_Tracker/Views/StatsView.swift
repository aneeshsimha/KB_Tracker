// StatsView.swift
// KB_Tracker

import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Environment(\.dismiss) private var dismiss

    // MARK: - Derived stats

    private var totalSessions: Int { sessions.count }
    private var totalRounds: Int { sessions.reduce(0) { $0 + $1.completedRounds } }
    private var totalHours: Double { sessions.reduce(0.0) { $0 + $1.totalDuration } / 3600 }

    private var allSetTimes: [TimeInterval] { sessions.compactMap(SessionMetrics.measuredDuration) }
    private var avgSetTime: TimeInterval? {
        guard !allSetTimes.isEmpty else { return nil }
        return allSetTimes.reduce(0, +) / Double(allSetTimes.count)
    }
    private var bestSetTime: TimeInterval? { allSetTimes.min() }

    // MARK: - 8-week bucketing

    private var weekBuckets: [WeekBucket] {
        let cal = Calendar.current
        let now = Date()
        return (0..<8).reversed().map { weekOffset in
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                  let weekInterval = cal.dateInterval(of: .weekOfYear, for: weekStart) else {
                return WeekBucket(weekOffset: weekOffset, sessionCount: 0, setTimes: [], totalReps: 0)
            }
            let weekSessions = sessions.filter { weekInterval.contains($0.date) }
            let setTimes = weekSessions.compactMap(SessionMetrics.measuredDuration)
            let totalReps = weekSessions.compactMap(\.recordedReps).reduce(0, +)
            return WeekBucket(
                weekOffset: weekOffset,
                sessionCount: weekSessions.count,
                setTimes: setTimes,
                totalReps: totalReps
            )
        }
    }

    private var volumeSeries: [TimeInterval] { weekBuckets.map { TimeInterval($0.sessionCount) } }
    private var avgSetSeries: [TimeInterval] {
        weekBuckets.map { bucket in
            let times = bucket.setTimes
            guard !times.isEmpty else { return 0 }
            return times.reduce(0, +) / Double(times.count)
        }
    }
    private var repsSeries: [TimeInterval] { weekBuckets.map { TimeInterval($0.totalReps) } }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    IconButton(icon: .back) { dismiss() }
                    Spacer()
                    Eyebrow("STATS")
                    Spacer()
                    Color.clear.frame(width: 32, height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)

                if sessions.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Eyebrow("NO DATA YET")
                        Text("Complete a workout to see your stats.")
                            .font(AppTypography.bodyText)
                            .foregroundColor(AppColors.ink2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {

                            // Lifetime totals
                            HStack(spacing: 8) {
                                StatTile(label: "SESSIONS", value: "\(totalSessions)")
                                StatTile(label: "ROUNDS", value: "\(totalRounds)")
                                StatTile(label: "HOURS", value: String(format: "%.1f", totalHours))
                            }

                            weeklyCard("WEEKLY SESSIONS", volumeSeries, mode: .rounds)
                            weeklyCard("WEEKLY AVG SET TIME", avgSetSeries, mode: .emom)
                            weeklyCard("WEEKLY REPS", repsSeries, mode: .rounds)
                            movementCard

                            // Lifetime averages
                            HStack(spacing: 8) {
                                StatTile(label: "AVG SET", value: avgSetTime.map { $0.formattedMinutesSecondsPadded } ?? "–")
                                StatTile(label: "BEST SET", value: bestSetTime.map { $0.formattedMinutesSecondsPadded } ?? "–")
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    // Weekly bar card: title, 8 bars, week axis
    private func weeklyCard(_ title: String, _ series: [TimeInterval], mode: WorkoutMode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(title)
            SparkBars(times: series, mode: mode, height: 48)
            weekLabels
        }
        .padding(16)
        .kbCard()
    }

    // Week axis labels (8 columns, oldest→newest)
    private var weekLabels: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekBuckets.enumerated()), id: \.offset) { _, bucket in
                Text(bucket.weekOffset == 0 ? "NOW" : "W-\(bucket.weekOffset)")
                    .font(AppTypography.mono(9))
                    .foregroundColor(AppColors.ink4)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var movementCard: some View {
        let movements = SessionMetrics.movementReps(sessions).sorted { $0.value > $1.value }
        let volume = SessionMetrics.movementVolume(sessions)
        let completion = sessions.compactMap(SessionMetrics.completionRate)
        return VStack(alignment: .leading, spacing: 8) {
            Eyebrow("RECORDED REPS BY MOVEMENT")
            if movements.isEmpty { Text("–  No recorded movement reps").font(AppTypography.bodyText).foregroundColor(AppColors.ink3) }
            else { ForEach(movements, id: \.key) { Text("\($0.key)  \($0.value) reps  ·  \(volume[$0.key, default: 0].formatted(.number.precision(.fractionLength(0...1)))) kg").font(AppTypography.mono(14)).foregroundColor(AppColors.ink) } }
            Text("Completion rate: \(completion.isEmpty ? "–" : (completion.reduce(0, +) / Double(completion.count)).formatted(.percent.precision(.fractionLength(0))))").font(.caption).foregroundColor(AppColors.ink3)
            Text("Only actual recorded reps are included; estimates are excluded.").font(.caption).foregroundColor(AppColors.ink4)
        }.padding(16).kbCard()
    }
}

// MARK: - Week bucket

private struct WeekBucket {
    let weekOffset: Int
    let sessionCount: Int
    let setTimes: [TimeInterval]
    let totalReps: Int
}

#Preview {
    NavigationStack {
        StatsView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
