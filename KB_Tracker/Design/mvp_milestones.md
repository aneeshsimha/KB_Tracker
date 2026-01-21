# Design - MVP Milestones

## MVP Requirements
- Rename `Colors.swift` → `AppColors.swift`
- Rename `Typography.swift` → `AppTypography.swift`

## Milestones

### Milestone 1: Rename Design Files
- [ ] Rename `Colors.swift` → `AppColors.swift`
- [ ] Update enum/struct name to AppColors
- [ ] Rename `Typography.swift` → `AppTypography.swift`
- [ ] Update enum/struct name to AppTypography

### Milestone 2: Update References
- [ ] Update all imports referencing Colors
- [ ] Update all imports referencing Typography
- [ ] Verify UI colors render correctly

### Milestone 3: (Post-MVP) Add AppConstants
- [ ] Create `AppConstants.swift`
- [ ] Centralize magic numbers (animation durations, sizes, etc.)
- [ ] Update views to use constants

## Verification
- [ ] App builds successfully
- [ ] All colors display correctly
- [ ] All typography renders correctly
- [ ] No old references remain
