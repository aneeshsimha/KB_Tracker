# Resources/ Folder Plan

## Purpose
Contains app resources like assets and sound files.

## Current State
- `Assets.xcassets` exists in root KB_Tracker folder
- No Sounds folder

## Target Files
| File/Folder | Status | Description |
|-------------|--------|-------------|
| `Assets.xcassets` | Move | App icons, colors, images |
| `Sounds/` | Create | Audio files for beeps (optional, currently using system sounds) |

## Tasks

### 1. Move Assets.xcassets
- [ ] Move from `KB_Tracker/Assets.xcassets` → `KB_Tracker/Resources/Assets.xcassets`
- [ ] Update Xcode project file references

### 2. Create Sounds/ folder (Optional)
- [ ] Create folder for custom audio files
- [ ] Add custom beep sounds if desired (currently using system sounds)

## Implementation Notes

### Current Audio Approach
The app currently uses system sounds via `AudioServicesPlaySystemSound`:
- `1104` - Soft tick (countdown)
- `1103` - Metallic ping (go beep)
- `1025` - Fanfare (completion)

### Future Enhancement: Custom Sounds
If custom sounds are desired:
1. Add `.wav` or `.caf` files to `Resources/Sounds/`
2. Update AudioService to load and play custom sounds
3. Example sound files:
   - `countdown_beep.wav`
   - `go_beep.wav`
   - `completion.wav`

```swift
// Example: Loading custom sound
if let soundURL = Bundle.main.url(forResource: "countdown_beep", withExtension: "wav") {
    var soundID: SystemSoundID = 0
    AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
    AudioServicesPlaySystemSound(soundID)
}
```

## Folder Structure
```
Resources/
├── Assets.xcassets/
│   ├── AccentColor.colorset/
│   ├── AppIcon.appiconset/
│   └── Contents.json
└── Sounds/
    └── (optional audio files)
```

## Dependencies
- None

## Testing
- App icon should display correctly
- Asset colors should load correctly
- (If custom sounds added) sounds should play correctly
