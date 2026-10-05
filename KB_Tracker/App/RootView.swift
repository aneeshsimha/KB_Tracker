// RootView.swift
// KB_Tracker
//
// First-launch gate: show onboarding once, then the main app.

import SwiftUI

struct RootView: View {
    @AppStorage("kb_onboarded") private var onboarded = false
    @AppStorage("kb_pref_kbType") private var prefKBType = KBType.double
    @AppStorage("kb_pref_weight") private var prefWeight = 20

    var body: some View {
        Group {
            if onboarded || ProcessInfo.processInfo.environment["KB_UI_TESTING"] == "1" {
                NavigationStack {
                    HomeView()
                }
            } else {
                OnboardingView { kbType, weight in
                    prefKBType = kbType
                    prefWeight = weight
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onboarded = true
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(AppColors.ink)
    }
}
