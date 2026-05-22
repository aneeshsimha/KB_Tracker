// RootView.swift
// KB_Tracker
//
// First-launch gate: show onboarding once, then the main app.

import SwiftUI

struct RootView: View {
    @AppStorage("kb_onboarded") private var onboarded = false
    @AppStorage("kb_pref_kbType") private var prefKBType = KBType.double.rawValue
    @AppStorage("kb_pref_weight") private var prefWeight = 20

    var body: some View {
        Group {
            if onboarded {
                NavigationStack {
                    HomeView()
                }
            } else {
                OnboardingView { kbType, weight in
                    prefKBType = kbType.rawValue
                    prefWeight = weight
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onboarded = true
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(AppColors.accent)
    }
}
