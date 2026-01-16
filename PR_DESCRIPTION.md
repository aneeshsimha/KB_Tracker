# Make targetRounds selection required (no prefilled value)

## Summary
Changed the target rounds picker to require explicit user selection instead of having a prefilled default value of 15 rounds.

## Changes

### HomeView.swift
- Changed `targetRounds` from `Int = 15` to `Int? = nil` to remove prefilled value
- Updated START button to be disabled when in rounds mode and no rounds are selected
- Updated navigation logic to only proceed when `targetRounds` has a value

### DurationPicker.swift
- Changed `rounds` binding from `Int` to `Int?` to support optional selection
- Added "Select rounds" placeholder option in the picker
- Updated previews to reflect the new optional behavior

## Behavior
- When users select "ROUNDS" mode, the target rounds picker now shows "Select rounds" as the default option
- Users must explicitly select a number of rounds (5, 8, 10, 12, 15, 18, 20, 25, or 30) before starting
- The START button remains disabled until a rounds value is selected
- This matches the UI design shown in the app mockup where users must actively choose their target rounds

## Testing
- Verify that rounds mode shows "Select rounds" by default
- Verify that START button is disabled until rounds are selected
- Verify that selecting a rounds value enables the START button
- Verify that the workout starts correctly with the selected rounds value
