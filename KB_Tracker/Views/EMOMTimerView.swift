// EMOMTimerView.swift
// KB_Tracker
//
// Active workout screen for EMOM mode

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

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                header

                Spacer()

                timerContent

                Spacer()

                if viewModel.emomPhase == .active {
                    setDoneButton
                }

                if let lastTime = viewModel.setTimes.last {
                    Text("Last set: \(lastTime.formattedMinutesSeconds)")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(24)
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
        .onChange(of: viewModel.emomPhase) { _, newPhase in
            if newPhase == .complete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    navigateToSummary = true
                }
            }
        }
        .alert("Exit Workout?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save Progress", role: .none) {
                viewModel.savePartialWorkout()
                navigateToSummary = true
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Would you like to save your progress or discard this workout?")
        }
        .navigationDestination(isPresented: $navigateToSummary) {
            if let session = viewModel.session {
                WorkoutCompleteView(session: session) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(viewModel.weightDisplay)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(action: { showExitConfirmation = true }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Timer Content

    @ViewBuilder
    private var timerContent: some View {
        switch viewModel.emomPhase {
        case .getReady:
            VStack(spacing: 16) {
                Text("GET READY")
                    .font(AppTypography.roundCounter)
                    .foregroundColor(AppColors.textSecondary)
                TimerDisplay(seconds: viewModel.getReadyCountdown, label: nil)
            }

        case .active:
            VStack(spacing: 16) {
                TimerDisplay(
                    seconds: viewModel.countdownSeconds,
                    isOvertime: viewModel.isOvertime,
                    label: "ROUND \(viewModel.currentRound)/\(config.targetRounds)"
                )

                Text("Total: \(viewModel.totalElapsed.formattedMinutesSeconds)")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }

        case .complete:
            VStack(spacing: 16) {
                Text("COMPLETE!")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)
                Text("\(viewModel.currentRound) rounds")
                    .font(AppTypography.roundCounter)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - SET DONE Button

    private var setDoneButton: some View {
        Button(action: { viewModel.handleEMOMSetDone() }) {
            Text(viewModel.isSetInProgress ? "SET DONE" : "WAITING...")
                .font(AppTypography.button)
                .foregroundColor(viewModel.isSetInProgress ? AppColors.background : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background {
                    if viewModel.isSetInProgress {
                        AppColors.accentGradient
                    } else {
                        LinearGradient(colors: [AppColors.surface, AppColors.surface], startPoint: .leading, endPoint: .trailing)
                    }
                }
                .cornerRadius(8)
        }
        .disabled(!viewModel.isSetInProgress)
    }
}

#Preview {
    NavigationStack {
        EMOMTimerView(config: .emom(kettlebellType: .double, weight: 20, minutes: 3))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
