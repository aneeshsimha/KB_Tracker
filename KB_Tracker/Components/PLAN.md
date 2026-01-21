# Components/ Folder Plan

## Purpose
Contains reusable UI components used across multiple views.

## Current State
| File | Description |
|------|-------------|
| `WeightPicker.swift` | Weight selection (Single/Double + kg) |
| `DurationPicker.swift` | Duration/rounds selection (includes RoundsPickerSheet) |
| `TimerDisplay.swift` | Large countdown timer display |

## Target Files
| File | Status | Description |
|------|--------|-------------|
| `WeightPicker.swift` | Keep | No changes needed |
| `DurationPicker.swift` | Keep | No changes needed |
| `TimerDisplay.swift` | Keep | No changes needed |
| `RoundProgressBar.swift` | Create | Visual progress indicator |
| `SessionCard.swift` | Create | History list item component |

## Tasks

### 1. Create RoundProgressBar.swift
- [ ] Visual ring/bar showing completed vs target rounds
- [ ] Used in timer views to show progress
- [ ] Animated fill as rounds complete

### 2. Create SessionCard.swift
- [ ] Extract session row from HistoryView
- [ ] Reusable card showing: date, weight, rounds, mode
- [ ] Tap to navigate to detail

### 3. Optional: Extract RoundsPickerSheet
- [ ] Move RoundsPickerSheet from DurationPicker.swift to its own file
- [ ] More modular, easier to maintain

## Implementation Notes

### RoundProgressBar.swift
```swift
// RoundProgressBar.swift

import SwiftUI

struct RoundProgressBar: View {
    let completed: Int
    let total: Int
    var accentColor: Color = AppColors.accent

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.surface)

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(accentColor)
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        RoundProgressBar(completed: 7, total: 20)
        RoundProgressBar(completed: 15, total: 20)
        RoundProgressBar(completed: 20, total: 20)
    }
    .padding()
    .background(AppColors.background)
}
```

### SessionCard.swift
```swift
// SessionCard.swift

import SwiftUI

struct SessionCard: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 8) {
                Text(session.weightDisplay)
                Text("·")
                Text(session.roundsDisplay)
                Text("·")
                Text(session.mode == .emom ? "EMOM" : "Rounds")
            }
            .font(AppTypography.sectionHeader)
            .foregroundColor(AppColors.textSecondary)

            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
    }
}
```

## Dependencies
- Design/AppColors.swift
- Design/AppTypography.swift
- Models/WorkoutSession.swift

## Testing
- RoundProgressBar animates correctly
- SessionCard displays all session info
- Components render in previews
