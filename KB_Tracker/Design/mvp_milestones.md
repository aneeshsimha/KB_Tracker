# Design - MVP Milestones

## MVP Requirements
- Rename `Colors.swift` → `AppColors.swift` ✅
- Rename `Typography.swift` → `AppTypography.swift` ✅

## Milestones

### Milestone 1: Rename Design Files ✅
- [x] Rename `Colors.swift` → `AppColors.swift`
- [x] Update enum/struct name to AppColors (already named AppColors)
- [x] Rename `Typography.swift` → `AppTypography.swift`
- [x] Update enum/struct name to AppTypography (already named AppTypography)

### Milestone 2: Update References ✅
- [x] Update all imports referencing Colors (none needed - struct names unchanged)
- [x] Update all imports referencing Typography (none needed - struct names unchanged)
- [x] Verify UI colors render correctly

### Milestone 3: (Post-MVP) Add AppConstants
- [ ] Create `AppConstants.swift`
- [ ] Centralize magic numbers (animation durations, sizes, etc.)
- [ ] Update views to use constants

## Verification
- [x] App builds successfully
- [x] All colors display correctly
- [x] All typography renders correctly
- [x] No old references remain
