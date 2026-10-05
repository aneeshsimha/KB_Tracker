import SwiftUI

struct SessionComparisonView: View {
    let first: WorkoutSession
    let second: WorkoutSession

    private var comparable: Bool { SessionMetrics.isComparablePace(first, second) }
    private func pace(_ session: WorkoutSession) -> String {
        guard let duration = SessionMetrics.measuredDuration(session) else { return "–" }
        return duration.formattedMinutesSecondsPadded
    }
    private func reps(_ session: WorkoutSession) -> String { session.recordedReps.map(String.init) ?? "–" }
    private func volume(_ session: WorkoutSession) -> String { session.recordedVolume.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " kg" } ?? "–" }
    private func completion(_ session: WorkoutSession) -> String { SessionMetrics.completionRate(session).map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "–" }
    private func prescription(_ session: WorkoutSession) -> String {
        guard let definition = session.definition else { return "Legacy prescription" }
        return definition.blocks.map { "\($0.name): \($0.rounds) × \($0.bells == 2 ? "2 × " : "")\($0.loadKg.formatted()) kg" }.joined(separator: "\n")
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Eyebrow("SESSION COMPARISON")
                Text(first.displayTitle).font(.system(size: 22, weight: .bold)).foregroundColor(AppColors.ink)
                HStack(alignment: .top) {
                    facts(first)
                    Divider().background(AppColors.hairline)
                    facts(second)
                }.padding(14).kbCard()
                if comparable {
                    comparisonRow("PACE", pace(first), pace(second))
                    let delta = (SessionMetrics.measuredDuration(second) ?? 0) - (SessionMetrics.measuredDuration(first) ?? 0)
                    comparisonRow("CHANGE", "–", delta == 0 ? "No change" : "\(delta > 0 ? "+" : "−")\(abs(delta).formattedMinutesSecondsPadded)")
                } else {
                    Text("Pace is available only for completed sessions with the same full prescription, load, and measured duration.")
                        .font(AppTypography.bodyText).foregroundColor(AppColors.ink2)
                    comparisonRow("PRESCRIPTION", prescription(first), prescription(second))
                }
                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Compare")
    }

    private func comparisonRow(_ label: String, _ left: String, _ right: String) -> some View {
        HStack { Eyebrow(label); Spacer(); Text(left).font(AppTypography.mono(16)); Text("→").foregroundColor(AppColors.ink4); Text(right).font(AppTypography.mono(16)) }
            .foregroundColor(AppColors.ink).padding(14).kbCard()
    }

    private func facts(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(session.date.formatted(date: .abbreviated, time: .shortened)).font(AppTypography.mono(11)).foregroundColor(AppColors.ink3)
            Text(session.displayTitle).font(.system(size: 15, weight: .semibold)).lineLimit(1)
            Text("Duration  \(pace(session))").font(AppTypography.mono(12))
            Text("Reps  \(reps(session))").font(AppTypography.mono(12))
            Text("Volume  \(volume(session))").font(AppTypography.mono(12))
            Text("Complete  \(completion(session))").font(AppTypography.mono(12))
        }.frame(maxWidth: .infinity, alignment: .leading).foregroundColor(AppColors.ink)
    }
}
