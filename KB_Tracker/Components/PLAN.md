# Components Directory

This directory contains reusable UI components used across multiple views.

---

## Files

### WeightPicker.swift

**Purpose:** Combined picker for kettlebell type (Single/Double) and weight (12-24kg)

**Interface:**
```swift
struct WeightPicker: View {
    @Binding var kettlebellType: KBType
    @Binding var weight: Int

    var body: some View { ... }
}
```

**Layout:**
```
WEIGHT
[Single ▼] [20 kg ▼]
    │           │
    └── Picker  └── Picker
```

**Implementation Notes:**

```swift
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
```

**Styling:**
- Labels in textSecondary
- Picker text in textPrimary (white)
- Menu style pickers (compact, tap to expand)
- Dark background inherited from parent

**Dependencies:**
- KBType enum (from Models)
- AppColors, AppTypography (from Design)

---

### DurationPicker.swift

**Purpose:** Pick workout duration (EMOM minutes) or rounds + rest (Rounds mode)

**Interface:**
```swift
struct DurationPicker: View {
    let mode: WorkoutMode
    @Binding var minutes: Int          // EMOM mode
    @Binding var rounds: Int           // Rounds mode
    @Binding var restSeconds: Int      // Rounds mode

    var body: some View { ... }
}
```

**Layout (EMOM mode):**
```
DURATION
[20 minutes ▼]
```

**Layout (Rounds mode):**
```
TARGET ROUNDS
[15 rounds ▼]

REST BETWEEN SETS
[60 seconds ▼]
```

**Implementation Notes:**

```swift
struct DurationPicker: View {
    let mode: WorkoutMode
    @Binding var minutes: Int
    @Binding var rounds: Int
    @Binding var restSeconds: Int

    // Minute options: 10, 12, 15, 18, 20, 22, 25, 30
    private let minuteOptions = [10, 12, 15, 18, 20, 22, 25, 30]

    // Round options: 5, 8, 10, 12, 15, 18, 20, 25, 30
    private let roundOptions = [5, 8, 10, 12, 15, 18, 20, 25, 30]

    // Rest options: 30, 45, 60, 90, 120 seconds
    private let restOptions = [30, 45, 60, 90, 120]

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

                    Picker("Rounds", selection: $rounds) {
                        ForEach(roundOptions, id: \.self) { r in
                            Text("\(r) rounds").tag(r)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.textPrimary)
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
```

**Dependencies:**
- WorkoutMode enum (from Models)
- AppColors, AppTypography (from Design)

---

### TimerDisplay.swift

**Purpose:** Large, prominent countdown display for active workout screens

**Interface:**
```swift
struct TimerDisplay: View {
    let seconds: Int                   // Countdown value
    let isOvertime: Bool               // Show warning styling
    let label: String?                 // Optional label below (e.g., "ROUND 7/20")

    var body: some View { ... }
}
```

**Layout:**
```
     0:47           ← Large monospace digits
   ROUND 7/20       ← Optional label
```

**Implementation Notes:**

```swift
struct TimerDisplay: View {
    let seconds: Int
    let isOvertime: Bool
    let label: String?

    private var timeString: String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(timeString)
                .font(AppTypography.timer)
                .monospacedDigit()              // Prevent layout shifts
                .foregroundColor(isOvertime ? AppColors.warning : AppColors.textPrimary)

            if let label = label {
                Text(label)
                    .font(AppTypography.roundCounter)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}
```

**Variants to Support:**
- Normal state: White numbers
- Overtime state: Red/warning color
- Get Ready state: Could show "GET READY" instead of numbers

**Animation:**
- Consider subtle pulse animation when countdown reaches 5-4-3-2-1
- Or scale animation on beep

**Dependencies:**
- AppColors, AppTypography (from Design)

---

## Usage Examples

**In HomeView:**
```swift
WeightPicker(
    kettlebellType: $kettlebellType,
    weight: $weight
)

DurationPicker(
    mode: mode,
    minutes: $targetMinutes,
    rounds: $targetRounds,
    restSeconds: $restDuration
)
```

**In EMOMTimerView:**
```swift
TimerDisplay(
    seconds: 60 - Int(secondsIntoMinute),
    isOvertime: secondsIntoMinute > 60,
    label: "ROUND \(currentRound)/\(targetMinutes)"
)
```

---

## Styling Consistency

All components should:
- Use `AppColors.background` for backgrounds (or be transparent)
- Use `AppColors.textPrimary` (white) for values
- Use `AppColors.textSecondary` for labels
- Use `AppTypography` for fonts
- Avoid borders/dividers unless necessary
- Keep spacing tight but readable
