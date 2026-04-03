// RoundsTimerView.swift
// KB_Tracker
//
// Active workout screen for Rounds-with-Rest mode

import SwiftUI
import SwiftData

struct RoundsTimerView: View {
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

                mainDisplay

                if viewModel.roundsPhase != .getReady {
                    Text("ROUND \(viewModel.currentRound)/\(config.targetRounds)")
                        .font(AppTypography.roundCounter)
                        .foregroundColor(AppColors.textPrimary)
                }

                if viewModel.roundsPhase != .getReady && viewModel.roundsPhase != .complete {
                    Text("Total: \(viewModel.totalElapsed.formattedMinutesSecondsPadded)")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                actionButton

                if let lastTime = viewModel.setTimes.last, viewModel.roundsPhase != .getReady {
                    Text("Last set: \(lastTime.formattedMinutesSecondsPadded)")
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
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Main Display

    @ViewBuilder
    private var mainDisplay: some View {
        switch viewModel.roundsPhase {
        case .getReady:
            VStack(spacing: 16) {
                Text("GET READY")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textSecondary)
                Text("\(viewModel.getReadyCountdown)")
                    .font(AppTypography.timer)
                    .foregroundColor(AppColors.textPrimary)
                    .monospacedDigit()
            }

        case .working:
            VStack(spacing: 16) {
                Text("WORKING")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.accent)
                Text(viewModel.currentSetElapsed.formattedMinutesSecondsPadded)
                    .font(AppTypography.timer)
                    .foregroundColor(AppColors.textPrimary)
                    .monospacedDigit()
            }

        case .resting:
            VStack(spacing: 16) {
                Text("REST")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textSecondary)
                Text("\(viewModel.restCountdown)")
                    .font(AppTypography.timer)
                    .foregroundColor(viewModel.restCountdown <= 5 ? AppColors.warning : AppColors.textPrimary)
                    .monospacedDigit()
            }

        case .complete:
            VStack(spacing: 16) {
                Text("COMPLETE!")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.accent)
                Text("\(viewModel.currentRound)/\(config.targetRounds)")
                    .font(AppTypography.timer)
                    .foregroundColor(AppColors.textPrimary)
                Text("rounds")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.roundsPhase {
        case .getReady:
            EmptyView()

        case .working:
            Button(action: { viewModel.handleRoundsSetDone() }) {
                Text("SET DONE")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(AppColors.accentGradient)
                    .cornerRadius(8)
            }

        case .resting:
            Button(action: { viewModel.skipRest() }) {
                Text("SKIP REST")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.surface)
                    .cornerRadius(8)
            }

        case .complete:
            Button(action: {
                navigateToSummary = true
            }) {
                Text("VIEW SUMMARY")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accentGradient)
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    RoundsTimerView(config: .rounds(kettlebellType: .double, weight: 20, rounds: 5, restSeconds: 30))
}
