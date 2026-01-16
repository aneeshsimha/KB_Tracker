// HomeView.swift
// KB_Tracker
//
// Main screen - workout configuration and start

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack {
                Text("KB Tracker")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text("Phase 1 Complete")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
