// PressLadderView.swift
// KB_Tracker
//
// Active press-ladder flow: rung indicator, focal rep count, LOG button,
// running stopwatch + total reps. Rest-as-needed (no enforced clock).

import SwiftUI
import SwiftData

struct PressLadderView: View {
    let config: WorkoutConfig

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: PressLadderViewModel

    @State private var showEndConfirm = false
    @State private var navigateToSummary = false

    init(config: WorkoutConfig) {
        self.config = config
        _vm = StateObject(wrappedValue: PressLadderViewModel(config: config))
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                rungIndicator.padding(.top, 18)

                Spacer()

                Text("\(vm.currentRungReps)")
                    .font(AppTypography.timerXL)
                    .foregroundColor(AppColors.ink)
                Eyebrow("reps this rung").padding(.top, 4)

                Text("\(vm.totalReps) total reps")
                    .font(AppTypography.mono(15, weight: .semibold))
                    .foregroundColor(AppColors.ink3)
                    .padding(.top, 24)

                Spacer()

                PrimaryButton(title: "Log \(vm.currentRungReps) Reps") { vm.logRung() }
                    .frame(height: 76)
                    .padding(.horizontal, 20)

                Button { vm.undoLastRung() } label: {
                    Text("Undo last rung")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.ink3)
                }
                .buttonStyle(TapScaleStyle())
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .onChange(of: vm.currentLadder) { _, _ in
            AudioService.shared.playGoBeep()
        }
        .onChange(of: vm.isComplete) { _, done in
            if done {
                AudioService.shared.playCompletionSound()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    navigateToSummary = true
                }
            }
        }
        .confirmSheet(
            isPresented: $showEndConfirm,
            title: "End this session?",
            message: "Your progress won't be saved.",
            confirmLabel: "End",
            cancelLabel: "Keep going"
        ) {
            dismiss()
        }
        .navigationDestination(isPresented: $navigateToSummary) {
            if let session = vm.session {
                WorkoutCompleteView(session: session) { dismiss() }
            }
        }
    }

    private var header: some View {
        HStack {
            Button { showEndConfirm = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: KBIcon.close.rawValue)
                    Text("END")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.ink2)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(AppColors.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppColors.hairline, lineWidth: 1))
            }
            .buttonStyle(TapScaleStyle())

            Spacer()
            Eyebrow("PRESS LADDER")
            Spacer()

            Text("\(vm.currentLadder)/\(vm.targetLadders)")
                .font(AppTypography.mono(12, weight: .regular))
                .foregroundColor(AppColors.ink3)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var rungIndicator: some View {
        HStack(spacing: 10) {
            ForEach(Array(PressLadderViewModel.rungs.enumerated()), id: \.offset) { i, reps in
                let isCurrent = i == vm.currentRungIndex
                Text("\(reps)")
                    .font(AppTypography.mono(16, weight: .bold))
                    .foregroundColor(isCurrent ? AppColors.background : AppColors.ink3)
                    .frame(width: 40, height: 40)
                    .background(isCurrent ? AppColors.ink : AppColors.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppColors.hairline, lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    NavigationStack {
        PressLadderView(config: .press(kettlebellType: .single, weight: 16, targetLadders: 5))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
