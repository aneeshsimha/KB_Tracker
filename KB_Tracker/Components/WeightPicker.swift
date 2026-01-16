// WeightPicker.swift
// KB_Tracker
//
// Reusable weight selection component (Single/Double + kg)

import SwiftUI

struct WeightPicker: View {
    @Binding var kettlebellType: KBType
    @Binding var weight: Int

    // Weight options: 12, 14, 16, 18, 20, 22, 24
    private let weights = Array(stride(from: 12, through: 24, by: 2))

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WEIGHT")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textSecondary)

            HStack(spacing: 12) {
                // KB Type picker
                Picker("Type", selection: $kettlebellType) {
                    Text("Single").tag(KBType.single)
                    Text("Double").tag(KBType.double)
                }
                .pickerStyle(.menu)
                .tint(AppColors.textPrimary)

                // Weight picker
                Picker("Weight", selection: $weight) {
                    ForEach(weights, id: \.self) { w in
                        Text("\(w) kg").tag(w)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppColors.textPrimary)
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        WeightPicker(
            kettlebellType: .constant(.double),
            weight: .constant(20)
        )
        .padding()
    }
}
