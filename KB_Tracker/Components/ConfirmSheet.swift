// ConfirmSheet.swift
// KB_Tracker
//
// Bottom-sheet destructive confirm (app.jsx abort / history.jsx delete).
// Dimmed blur backdrop, title + body, red primary action, ghost cancel.

import SwiftUI

struct ConfirmSheet: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    var confirmLabel: String = "Confirm"
    var cancelLabel: String = "Cancel"
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .background(.ultraThinMaterial)
                        .onTapGesture { isPresented = false }

                    VStack(alignment: .leading, spacing: 0) {
                        Text(title)
                            .font(AppTypography.titleMd)
                            .foregroundColor(AppColors.ink)
                            .padding(.bottom, 8)
                        Text(message)
                            .font(AppTypography.bodyText)
                            .foregroundColor(AppColors.ink2)
                            .padding(.bottom, 18)
                        PrimaryButton(title: confirmLabel,
                                      background: AppColors.red,
                                      foreground: AppColors.ink) {
                            isPresented = false
                            onConfirm()
                        }
                        .padding(.bottom, 10)
                        GhostButton(title: cancelLabel) { isPresented = false }
                    }
                    .padding(24)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surface)
                    .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
                    .overlay(
                        UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                            .stroke(AppColors.hairline, lineWidth: 1)
                    )
                    .transition(.move(edge: .bottom))
                }
                .animation(.easeOut(duration: 0.2), value: isPresented)
            }
        }
    }
}

extension View {
    func confirmSheet(isPresented: Binding<Bool>,
                      title: String,
                      message: String,
                      confirmLabel: String = "Confirm",
                      cancelLabel: String = "Cancel",
                      onConfirm: @escaping () -> Void) -> some View {
        modifier(ConfirmSheet(isPresented: isPresented, title: title, message: message,
                              confirmLabel: confirmLabel, cancelLabel: cancelLabel,
                              onConfirm: onConfirm))
    }
}
