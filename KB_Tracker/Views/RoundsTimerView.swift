// RoundsTimerView.swift
// KB_Tracker
//
// Active workout screen for Rounds-with-Rest mode (timer.jsx: ready / work / rest).

import SwiftUI
import SwiftData

struct RoundsTimerView: View {
    let config: WorkoutConfig

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: RoundsTimerViewModel

    @State private var showExitConfirmation: Bool = false
    @State private var navigateToSummary: Bool = false

    init(config: WorkoutConfig) {
        self.config = config
        _viewModel = StateObject(wrappedValue: RoundsTimerViewModel(config: config))
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TimerChrome(
                    label: chromeLabel,
                    current: max(0, viewModel.currentRound - 1),
                    total: config.targetRounds,
                    onEnd: { showExitConfirmation = true }
                )
                .padding(.horizontal, 20)
                .padding(.top, 14)

                Spacer(minLength: 0)

                content

                Spacer(minLength: 0)

                footer
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .onChange(of: viewModel.roundsPhase) { _, newPhase in
            if newPhase == .complete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    navigateToSummary = true
                }
            }
        }
        .confirmSheet(
            isPresented: $showExitConfirmation,
            title: "End this session?",
            message: "Your progress won't be saved.",
            confirmLabel: "End",
            cancelLabel: "Keep going",
            onConfirm: { dismiss() }
        )
        .navigationDestination(isPresented: $navigateToSummary) {
            if let session = viewModel.session {
                WorkoutCompleteView(session: session) { dismiss() }
            }
        }
    }

    private var chromeLabel: String {
        switch viewModel.roundsPhase {
        case .getReady: return "GET READY"
        case .working:  return "ROUND \(viewModel.currentRound)"
        case .resting:  return "REST"
        case .complete: return "DONE"
        }
    }

    // MARK: - Center content

    @ViewBuilder
    private var content: some View {
        switch viewModel.roundsPhase {
        case .getReady:
            GetReadyContent(
                eyebrow: "ROUNDS · STARTING",
                digit: max(1, viewModel.getReadyCountdown),
                weight: config.weightDisplay,
                detail: "\(config.targetRounds) rounds · \((config.restDuration ?? 0).formattedMinutesSecondsPadded) rest"
            )
        case .working:
            workContent
        case .resting:
            restContent
        case .complete:
            VStack(spacing: 12) {
                Eyebrow("ROUNDS · COMPLETE", color: AppColors.ink3)
                Text("\(viewModel.currentRound)")
                    .font(AppTypography.timerXL)
                    .foregroundColor(AppColors.ink)
                    .monospacedDigit()
            }
        }
    }

    private var workContent: some View {
        VStack(spacing: 0) {
            Text(viewModel.currentSetElapsed.formattedMinutesSecondsPadded)
                .font(AppTypography.timerXL)
                .foregroundColor(AppColors.ink)
                .monospacedDigit()
                .kerning(-4)

            Eyebrow("ELAPSED THIS ROUND", color: AppColors.ink3)
                .padding(.top, 12)

            ComplexReminderRow()
                .padding(.top, 28)
        }
        .padding(.horizontal, 8)
    }

    private var restContent: some View {
        VStack(spacing: 0) {
            Eyebrow("SET LOGGED", color: AppColors.ink3)
                .padding(.bottom, 6)

            Text((viewModel.setTimes.last ?? 0).formattedMinutesSecondsPadded)
                .font(AppTypography.mono(28, weight: .semibold))
                .foregroundColor(AppColors.ink2)
                .padding(.bottom, 40)

            Text(viewModel.restCountdown.formattedMinutesSecondsPadded)
                .font(AppTypography.numeral)
                .foregroundColor(AppColors.ink)
                .monospacedDigit()
                .kerning(-2)

            Eyebrow("UNTIL ROUND \(viewModel.currentRound + 1)", color: AppColors.ink3)
                .padding(.top, 12)

            restProgressBar
                .frame(width: 200, height: 4)
                .padding(.top, 28)
        }
    }

    private var restProgressBar: some View {
        let total = max(1, config.restDuration ?? 1)
        let done = total - viewModel.restCountdown
        let fraction = min(1, max(0, CGFloat(done) / CGFloat(total)))
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppColors.surface2)
                Capsule().fill(AppColors.ink)
                    .frame(width: geo.size.width * fraction)
            }
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        switch viewModel.roundsPhase {
        case .working:
            SetDoneFooter(setTimes: viewModel.setTimes) { viewModel.setDone() }

        case .resting:
            GhostButton(title: "Skip rest") { viewModel.skipRest() }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

        default:
            EmptyView()
        }
    }
}


#Preview {
    NavigationStack {
        RoundsTimerView(config: .rounds(kettlebellType: .double, weight: 16, rounds: 5, restSeconds: 60))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
