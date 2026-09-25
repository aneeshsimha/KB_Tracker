// EMOMTimerView.swift
// KB_Tracker
//
// Active workout screen for EMOM mode (timer.jsx: ready / work phases).

import SwiftUI
import SwiftData

struct EMOMTimerView: View {
    let config: WorkoutConfig

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: EMOMTimerViewModel

    @State private var showExitConfirmation: Bool = false
    @State private var navigateToSummary: Bool = false

    init(config: WorkoutConfig) {
        self.config = config
        _viewModel = StateObject(wrappedValue: EMOMTimerViewModel(config: config))
    }

    private var isOvertime: Bool { viewModel.isOvertime }

    var body: some View {
        ZStack {
            (isOvertime ? AppColors.overtimeBackground : AppColors.background)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.25), value: isOvertime)

            VStack(spacing: 0) {
                TimerChrome(
                    label: chromeLabel,
                    current: max(0, viewModel.currentRound - 1),
                    total: config.targetMinutes,
                    accent: isOvertime ? AppColors.red : AppColors.ink3,
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
        .onChange(of: viewModel.emomPhase) { _, newPhase in
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
        switch viewModel.emomPhase {
        case .getReady: return "GET READY"
        case .active:   return "MIN \(viewModel.currentRound)"
        case .complete: return "DONE"
        }
    }

    // MARK: - Center content

    @ViewBuilder
    private var content: some View {
        switch viewModel.emomPhase {
        case .getReady:
            GetReadyContent(
                eyebrow: "EMOM · STARTING",
                digit: max(1, viewModel.getReadyCountdown),
                weight: config.weightDisplay,
                detail: "\(config.targetMinutes) minutes EMOM"
            )
        case .active:
            workContent
        case .complete:
            VStack(spacing: 12) {
                Eyebrow("EMOM · COMPLETE", color: AppColors.ink3)
                Text("\(viewModel.currentRound)")
                    .font(AppTypography.timerXL)
                    .foregroundColor(AppColors.ink)
                    .monospacedDigit()
            }
        }
    }

    private var workContent: some View {
        VStack(spacing: 0) {
            Text(timerText)
                .font(.system(size: isOvertime ? 92 : 116, weight: .bold, design: .monospaced))
                .foregroundColor(isOvertime ? AppColors.red : AppColors.ink)
                .monospacedDigit()
                .kerning(-4)
                .animation(.easeOut(duration: 0.2), value: isOvertime)

            Eyebrow(isOvertime ? "OVERTIME" : "THIS MINUTE",
                    color: isOvertime ? AppColors.red : AppColors.ink3)
                .padding(.top, 12)

            ComplexReminderRow()
                .padding(.top, 28)
        }
        .padding(.horizontal, 8)
    }

    private var timerText: String {
        if isOvertime {
            return "+" + abs(viewModel.countdownSeconds).formattedMinutesSecondsPadded
        }
        return viewModel.countdownSeconds.formattedMinutesSecondsPadded
    }

    // MARK: - Footer (Set Done + last/avg)

    @ViewBuilder
    private var footer: some View {
        if viewModel.emomPhase == .active {
            SetDoneFooter(setTimes: viewModel.setTimes, overtime: isOvertime) { viewModel.setDone() }
        }
    }
}


#Preview {
    NavigationStack {
        EMOMTimerView(config: .emom(kettlebellType: .double, weight: 16, minutes: 20))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
