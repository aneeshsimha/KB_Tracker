// EMOMTimerView.swift
// KB_Tracker
//
// Active workout screen for EMOM mode

import SwiftUI
import SwiftData

struct EMOMTimerView: View {
    // Configuration passed in from HomeView
    let config: WorkoutConfig

    // Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // ViewModel
    @StateObject private var viewModel: TimerViewModel

    // UI state
    @State private var showExitConfirmation: Bool = false
    @State private var navigateToSummary: Bool = false
    @State private var completedSession: WorkoutSession? = nil
    @State private var partialSession: WorkoutSession? = nil

    init(config: WorkoutConfig) {
        self.config = config
        self._viewModel = StateObject(wrappedValue: TimerViewModel(config: config))
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                header

                Spacer()

                // Main timer display
                timerContent

                Spacer()

                // SET DONE button (only during active phase)
                if viewModel.emomPhase == .active {
                    setDoneButton
                }

                // Last set time
                if let lastTime = viewModel.setTimes.last {
                    Text("Last set: \(lastTime.formattedTime)")
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
                completedSession = viewModel.createSession(isCompleted: true)
                // Navigate to summary after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    navigateToSummary = true
                }
            }
        }
        .alert("Exit Workout?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save Progress", role: .none) {
                savePartialWorkout()
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Would you like to save your progress or discard this workout?")
        }
        .navigationDestination(isPresented: $navigateToSummary) {
            if let session = completedSession ?? partialSession {
                WorkoutCompleteView(session: session) {
                    // Exit the entire workout flow back to HomeView
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(config.weightDisplay)
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
                // Countdown display
                TimerDisplay(
                    seconds: viewModel.emomCountdownSeconds,
                    isOvertime: viewModel.isEMOMOvertime,
                    label: "ROUND \(viewModel.currentRound)/\(config.targetRounds)"
                )

                // Total elapsed time
                Text("Total: \(viewModel.totalElapsed.formattedTime)")
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
                .background(viewModel.isSetInProgress ? AppColors.accent : AppColors.surface)
                .cornerRadius(8)
        }
        .disabled(!viewModel.isSetInProgress)
    }

    // MARK: - Actions

    private func savePartialWorkout() {
        viewModel.stop()
        partialSession = viewModel.createSession(isCompleted: false)
        navigateToSummary = true
    }
}

#Preview {
    NavigationStack {
        EMOMTimerView(config: .emom(kettlebellType: .double, weight: 20, minutes: 3))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
