// DurationPicker.swift
// KB_Tracker
//
// Duration/rounds selection component

import SwiftUI

struct DurationPicker: View {
    let mode: WorkoutMode
    @Binding var minutes: Int          // EMOM mode
    @Binding var rounds: Int           // Rounds mode
    @Binding var restSeconds: Int      // Rounds mode

    // Minute options: 10, 12, 15, 18, 20, 22, 25, 30
    private let minuteOptions = [10, 12, 15, 18, 20, 22, 25, 30]

    // Round options: 5, 8, 10, 12, 15, 18, 20, 25, 30
    private let roundOptions = [5, 8, 10, 12, 15, 18, 20, 25, 30]

    // Rest options: 30, 45, 60, 90, 120 seconds
    private let restOptions = [30, 45, 60, 90, 120]
    
    @State private var showingRoundsPicker = false

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

                    Button(action: {
                        showingRoundsPicker = true
                    }) {
                        HStack {
                            Text("\(rounds) rounds")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(AppColors.surface)
                        .cornerRadius(8)
                    }
                }
                .sheet(isPresented: $showingRoundsPicker) {
                    RoundsPickerSheet(
                        selectedRounds: $rounds,
                        options: roundOptions,
                        isPresented: $showingRoundsPicker
                    )
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

// MARK: - Rounds Picker Sheet

struct RoundsPickerSheet: View {
    @Binding var selectedRounds: Int
    let options: [Int]
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("TARGET ROUNDS")
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.textSecondary)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .padding(20)
                
                // List of options
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                selectedRounds = option
                                isPresented = false
                            }) {
                                HStack {
                                    Text("\(option) rounds")
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    if selectedRounds == option {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppColors.accent)
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    selectedRounds == option
                                        ? AppColors.surface.opacity(0.5)
                                        : Color.clear
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if option != options.last {
                                Divider()
                                    .background(AppColors.border)
                                    .padding(.leading, 20)
                            }
                        }
                    }
                    .background(AppColors.surface)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
