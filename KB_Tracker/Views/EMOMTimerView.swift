// EMOMTimerView.swift
// KB_Tracker
//
// Active workout screen for EMOM mode (timer.jsx: ready / work phases).

import SwiftUI
import SwiftData

struct EMOMTimerView: View {
    let config: WorkoutConfig

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: TimerViewModel

    @State private var showExitConfirmation: Bool = false
    @State private var navigateToSummary: Bool = false

    init(config: WorkoutConfig) {
        self.config = config
        _viewModel = StateObject(wrappedValue: TimerViewModel(config: config))
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
            readyContent
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

    private var readyContent: some View {
        let digit = max(1, viewModel.getReadyCountdown)
        return VStack(spacing: 0) {
            Eyebrow("EMOM · STARTING", color: AppColors.ink3)
                .padding(.bottom, 16)

            Text("\(digit)")
                .font(.system(size: 220, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.ink)
                .monospacedDigit()
                .id(digit)
                .transition(.scale(scale: 0.94).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: digit)

            (
                Text("\(config.weightDisplay)")
                    .font(AppTypography.mono(18, weight: .semibold))
                + Text("  ·  ")
                    .foregroundColor(AppColors.ink4)
                + Text("\(config.targetMinutes) minutes EMOM")
                    .font(.system(size: 14))
            )
            .foregroundColor(AppColors.ink2)
            .padding(.top, 20)
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
            VStack(spacing: 12) {
                Button(action: { viewModel.handleEMOMSetDone() }) {
                    Text("Set Done")
                        .font(.system(size: 18, weight: .bold))
                        .kerning(18 * 0.08)
                        .textCase(.uppercase)
                        .foregroundColor(isOvertime ? AppColors.ink : AppColors.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 76)
                        .background(isOvertime ? AppColors.red : AppColors.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(TapScaleStyle())

                if !viewModel.setTimes.isEmpty {
                    HStack {
                        lastAvg(label: "Last set", value: viewModel.setTimes.last ?? 0)
                        Spacer()
                        lastAvg(label: "Avg", value: averageSetTime)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.ink3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func lastAvg(label: String, value: TimeInterval) -> some View {
        HStack(spacing: 6) {
            Text("\(label):")
            Text(value.formattedMinutesSecondsPadded)
                .font(AppTypography.mono(12, weight: .semibold))
                .foregroundColor(AppColors.ink2)
        }
    }

    private var averageSetTime: TimeInterval {
        guard !viewModel.setTimes.isEmpty else { return 0 }
        return viewModel.setTimes.reduce(0, +) / Double(viewModel.setTimes.count)
    }
}


#Preview {
    NavigationStack {
        EMOMTimerView(config: .emom(kettlebellType: .double, weight: 16, minutes: 20))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
