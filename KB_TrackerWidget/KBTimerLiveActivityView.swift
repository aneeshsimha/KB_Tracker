// KBTimerLiveActivityView.swift
// KB_TrackerWidget

import ActivityKit
import SwiftUI
import WidgetKit

struct KBTimerLiveActivityView: View {
    let context: ActivityViewContext<KBTimerAttributes>

    private var state: KBTimerAttributes.ContentState { context.state }
    private var phaseLabel: String {
        switch state.phase {
        case "getReady":  return "GET READY"
        case "resting":   return "REST"
        case "complete":  return "DONE"
        default:          return state.mode == "emom" ? "EMOM" : "WORK"
        }
    }
    private var roundText: String { "\(state.currentRound)/\(state.totalRounds)" }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(phaseLabel)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                Text(roundText)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(workoutTypeLabel)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                Text(elapsedFormatted)
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(Color(red: 0.02, green: 0.02, blue: 0.02))
    }

    private var workoutTypeLabel: String {
        switch context.attributes.workoutType {
        case "snatchTest":    return "SNATCH"
        case "swingInterval": return "SWING"
        case "press":         return "PRESS"
        default:              return "ABC"
        }
    }

    private var elapsedFormatted: String {
        let s = Int(state.elapsedSeconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

struct KBTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KBTimerAttributes.self) { context in
            KBTimerLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text(context.state.phase == "resting" ? "REST" : "ROUND")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(context.state.currentRound)/\(context.state.totalRounds)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("ELAPSED")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                        let s = Int(context.state.elapsedSeconds)
                        Text(String(format: "%d:%02d", s / 60, s % 60))
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
            } compactLeading: {
                Text("\(context.state.currentRound)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            } compactTrailing: {
                Text("/\(context.state.totalRounds)")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            } minimal: {
                Text("\(context.state.currentRound)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }
}
