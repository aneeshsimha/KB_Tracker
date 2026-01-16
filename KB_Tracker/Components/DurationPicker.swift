// DurationPicker.swift
// KB_Tracker
//
// Duration/rounds selection component

import SwiftUI

struct DurationPicker: View {
    let mode: WorkoutMode
    @Binding var minutes: Int
    @Binding var rounds: Int
    @Binding var restSeconds: Int

    // Minute options: 10, 12, 15, 18, 20, 22, 25, 30
    private let minuteOptions = [10, 12, 15, 18, 20, 22, 25, 30]

    // Round options: 5, 8, 10, 12, 15, 18, 20, 25, 30
    private let roundOptions = [5, 8, 10, 12, 15, 18, 20, 25, 30]

    // Rest options: 30, 45, 60, 90, 120 seconds
    private let restOptions = [30, 45, 60, 90, 120]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if mode == .emom {
                // EMOM: Just minutes
                VStack(alignment: .leading, spacing: 8) {
                    Text("DURATION")
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.textSecondary)

                    Picker("Minutes", selection: $minutes) {
                        ForEach(minuteOptions, id: \.self) { m in
                            Text("\(m) minutes").tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.textPrimary)
                }
            } else {
                // Rounds: Target rounds + rest
                VStack(alignment: .leading, spacing: 8) {
                    Text("TARGET ROUNDS")
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.textSecondary)

                    Picker("Rounds", selection: $rounds) {
                        ForEach(roundOptions, id: \.self) { r in
                            Text("\(r) rounds").tag(r)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.textPrimary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("REST BETWEEN SETS")
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.textSecondary)

                    Picker("Rest", selection: $restSeconds) {
                        ForEach(restOptions, id: \.self) { s in
                            Text("\(s) seconds").tag(s)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.textPrimary)
                }
            }
        }
    }
}

#Preview("EMOM Mode") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        DurationPicker(
            mode: .emom,
            minutes: .constant(20),
            rounds: .constant(15),
            restSeconds: .constant(60)
        )
        .padding()
    }
}

#Preview("Rounds Mode") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        DurationPicker(
            mode: .rounds,
            minutes: .constant(20),
            rounds: .constant(15),
            restSeconds: .constant(60)
        )
        .padding()
    }
}
