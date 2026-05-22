// OnboardingView.swift
// KB_Tracker
//
// First-run flow (ported from onboarding.jsx). 4 steps with a thin progress
// rail at top: Welcome → WhatsABC → PickEquipment → Ready.

import SwiftUI

struct OnboardingView: View {
    /// Called when the user finishes onboarding. Args: chosen kettlebell type and weight (kg).
    let onComplete: (KBType, Int) -> Void

    @State private var step: Int = 0
    // Pre-seeded equipment so step 3 has something to render (matches prototype).
    @State private var kbType: KBType = .double
    @State private var weight: Int = 16

    init(onComplete: @escaping (KBType, Int) -> Void) {
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            // progress rail
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(i <= step ? AppColors.ink : AppColors.surface3)
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ZStack {
                switch step {
                case 0:
                    OB_Welcome(onNext: { step = 1 })
                case 1:
                    OB_WhatsABC(onNext: { step = 2 }, onBack: { step = 0 })
                case 2:
                    OB_PickEquipment(kbType: $kbType, weight: $weight,
                                     onNext: { step = 3 }, onBack: { step = 1 })
                default:
                    OB_Ready(kbType: kbType, weight: weight,
                             onDone: { onComplete(kbType, weight) },
                             onBack: { step = 2 })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(step)
            .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColors.background.ignoresSafeArea())
        .animation(.easeOut(duration: 0.24), value: step)
    }
}

// MARK: - Step 1: hero welcome

fileprivate struct OB_Welcome: View {
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 0) {
                KettlebellGlyph(size: 84, double: true)
                    .padding(.bottom, 28)
                Eyebrow("KB · TRACKER")
                    .padding(.bottom, 14)
                Text("The Armor\nBuilding\nComplex.")
                    .font(.system(size: 40, weight: .heavy))
                    .tracking(-1)
                    .lineSpacing(0)
                    .foregroundColor(AppColors.ink)
                    .padding(.bottom, 16)
                Text("Two cleans. One press. Three front squats. Stack the rounds. That's it.")
                    .font(AppTypography.bodyText)
                    .lineSpacing(15 * 0.45)
                    .foregroundColor(AppColors.ink2)
                    .frame(maxWidth: 280, alignment: .leading)
            }
            Spacer(minLength: 0)
            VStack(spacing: 12) {
                PrimaryButton(title: "Begin", action: onNext)
                Text("No accounts. Your sessions live on your phone.")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.ink4)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

// MARK: - Step 2: explainer for the two modes

fileprivate struct OB_WhatsABC: View {
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                IconButton(icon: .back, action: onBack)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 14)

            Eyebrow("HOW IT WORKS")
                .padding(.bottom, 10)
            Text("One complex.\nTwo clocks.")
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.5)
                .lineSpacing(32 * 0.05)
                .foregroundColor(AppColors.ink)
                .padding(.bottom, 18)

            // the complex card
            KBCard(padding: 18) {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("THE COMPLEX · 1 ROUND")
                        .padding(.bottom, 12)
                    HStack(spacing: 12) {
                        OB_Movement(n: "2", label: "Cleans")
                        OB_Movement(n: "1", label: "Press")
                        OB_Movement(n: "3", label: "F. Squats")
                    }
                }
            }
            .padding(.bottom, 14)

            OB_ModeCard(tag: "MODE 01", title: "EMOM",
                        desc: "Every Minute On the Minute. Start a round at the top of each minute, rest in whatever time you have left.",
                        bigGlyph: "60s")
            Spacer().frame(height: 10)
            OB_ModeCard(tag: "MODE 02", title: "Rounds",
                        desc: "Fixed rounds with a set rest period. Tap Set Done, the rest timer runs, then the next round starts.",
                        bigGlyph: "×N")

            Spacer(minLength: 0)
            PrimaryButton(title: "Continue", action: onNext)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

fileprivate struct OB_Movement: View {
    let n: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(n)
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .tracking(-1)
                .foregroundColor(AppColors.ink)
            Text(label.uppercased())
                .font(.system(size: 11))
                .kerning(0.5)
                .foregroundColor(AppColors.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .kbCard(cornerRadius: 14, fill: AppColors.surface2, stroke: AppColors.hairline)
    }
}

fileprivate struct OB_ModeCard: View {
    let tag: String
    let title: String
    let desc: String
    let bigGlyph: String

    var body: some View {
        HStack(spacing: 14) {
            Text(bigGlyph)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.ink)
                .frame(width: 64, height: 64)
                .kbCard(cornerRadius: 14, fill: AppColors.surface2, stroke: AppColors.hairline)

            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(tag)
                Text(title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(AppColors.ink)
                Text(desc)
                    .font(.system(size: 12.5))
                    .lineSpacing(12.5 * 0.35)
                    .foregroundColor(AppColors.ink3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .kbCard()
    }
}

// MARK: - Step 3: equipment

fileprivate struct OB_PickEquipment: View {
    @Binding var kbType: KBType
    @Binding var weight: Int
    let onNext: () -> Void
    let onBack: () -> Void

    private let weights: [Int] = Array(stride(from: 12, through: 24, by: 2))
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                IconButton(icon: .back, action: onBack)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 14)

            Eyebrow("STEP 02 · KIT")
                .padding(.bottom, 10)
            Text("What are you\nswinging?")
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.5)
                .lineSpacing(32 * 0.05)
                .foregroundColor(AppColors.ink)
                .padding(.bottom, 22)

            // single / double
            Eyebrow("BELLS")
                .padding(.bottom, 8)
            SegmentedToggle(options: [
                SegmentedOption(label: "Single", value: KBType.single),
                SegmentedOption(label: "Double", value: KBType.double),
            ], selection: $kbType)
            .padding(.bottom, 22)

            // weight chooser
            Eyebrow(kbType == .double ? "WEIGHT · KG (EACH)" : "WEIGHT · KG")
                .padding(.bottom, 8)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weights, id: \.self) { w in
                    OB_WeightChip(value: w, on: weight == w) { weight = w }
                }
            }
            .padding(.bottom, 22)

            // live readout
            HStack(spacing: 14) {
                KettlebellGlyph(size: 56, double: kbType == .double)
                VStack(alignment: .leading, spacing: 2) {
                    Eyebrow("YOUR SETUP")
                    HStack(spacing: 0) {
                        Text(kbType == .double ? "2 × \(weight)kg" : "1 × \(weight)kg")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.ink)
                        Text(kbType == .double ? " · \(weight * 2)kg total" : " · single bell")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.ink3)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .kbCard()

            Spacer(minLength: 0)
            PrimaryButton(title: "Continue", action: onNext)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

fileprivate struct OB_WeightChip: View {
    let value: Int
    let on: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .tracking(-0.5)
                .foregroundColor(on ? AppColors.background : AppColors.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(on ? AppColors.ink : AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(on ? AppColors.ink : AppColors.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(TapScaleStyle())
    }
}

// MARK: - Step 4: confirm + finish

fileprivate struct OB_Ready: View {
    let kbType: KBType
    let weight: Int
    let onDone: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                IconButton(icon: .back, action: onBack)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 14)

            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 0) {
                KettlebellGlyph(size: 64, double: kbType == .double)
                    .padding(.bottom, 24)
                Eyebrow("YOU'RE SET")
                    .padding(.bottom, 12)
                Text("Pick a clock,\npick a target,\nstart moving.")
                    .font(.system(size: 38, weight: .heavy))
                    .tracking(-1)
                    .lineSpacing(38 * 0.02)
                    .foregroundColor(AppColors.ink)
                    .padding(.bottom, 20)
                Text("You can change your bells, mode and duration on the home screen before every session.")
                    .font(AppTypography.bodyText)
                    .lineSpacing(15 * 0.45)
                    .foregroundColor(AppColors.ink2)
                    .frame(maxWidth: 280, alignment: .leading)
            }
            Spacer(minLength: 0)

            PrimaryButton(title: "Enter the App", action: onDone)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

#Preview {
    OnboardingView { _, _ in }
}
