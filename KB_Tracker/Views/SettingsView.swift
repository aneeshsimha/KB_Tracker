// SettingsView.swift
// KB_Tracker

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("kb_pref_kbType") private var prefKBTypeRaw: String = KBType.double.rawValue
    @AppStorage("kb_pref_weight") private var prefWeight: Int = 20
    @AppStorage("kb_pref_sound") private var soundEnabled: Bool = true
    @AppStorage("kb_pref_getReady") private var getReadySeconds: Int = 5

    private var prefKBType: KBType {
        KBType(rawValue: prefKBTypeRaw) ?? .double
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Eyebrow("SETTINGS")
                    Spacer()
                    IconButton(icon: .close) { dismiss() }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // KB Type
                        VStack(alignment: .leading, spacing: 8) {
                            Eyebrow("KETTLEBELL TYPE")
                            SegmentedToggle(
                                options: [
                                    SegmentedOption(label: "SINGLE", value: KBType.single),
                                    SegmentedOption(label: "DOUBLE", value: KBType.double),
                                ],
                                selection: Binding(
                                    get: { prefKBType },
                                    set: { prefKBTypeRaw = $0.rawValue }
                                )
                            )
                        }

                        // Weight
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Eyebrow("DEFAULT WEIGHT")
                                Text("\(prefWeight) kg")
                                    .font(AppTypography.mono(28))
                                    .foregroundColor(AppColors.ink)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                StepperButton(icon: .minus) {
                                    if prefWeight > WorkoutParameters.weightMin {
                                        prefWeight -= WorkoutParameters.weightStep
                                    }
                                }
                                StepperButton(icon: .plus) {
                                    if prefWeight < WorkoutParameters.weightMax {
                                        prefWeight += WorkoutParameters.weightStep
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .kbCard()

                        // Sound
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Eyebrow("SOUND")
                                Text(soundEnabled ? "On" : "Off")
                                    .font(AppTypography.bodyText)
                                    .foregroundColor(AppColors.ink2)
                            }
                            Spacer()
                            Toggle("", isOn: $soundEnabled)
                                .labelsHidden()
                                .tint(AppColors.green)
                        }
                        .padding(16)
                        .kbCard()

                        // Get-ready duration
                        VStack(alignment: .leading, spacing: 8) {
                            Eyebrow("GET-READY COUNTDOWN")
                            HStack(spacing: 8) {
                                ForEach(WorkoutParameters.getReadyOptions, id: \.self) { seconds in
                                    Button {
                                        getReadySeconds = seconds
                                    } label: {
                                        Text("\(seconds)s")
                                            .font(AppTypography.mono(13))
                                            .foregroundColor(getReadySeconds == seconds ? AppColors.background : AppColors.ink)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(getReadySeconds == seconds ? AppColors.ink : AppColors.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(AppColors.hairline, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(TapScaleStyle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}
