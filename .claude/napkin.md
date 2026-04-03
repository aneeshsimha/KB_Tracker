# Napkin — KB_Tracker (ARMOR)

## Corrections
| Date | Source | What Went Wrong | What To Do Instead |
|------|--------|----------------|-------------------|
| 2026-04-02 | self | Claimed to have Xcode MCP tools (BuildProject, RenderPreview, etc.) but they weren't available | Check ToolSearch results before claiming tool availability — use xcodebuild CLI instead |

## User Preferences
- User wants kettlebell workout app features
- App is branded "ARMOR", bundle ID `aniche-studios.KB-Tracker`
- Using Conductor with parallel agents — user is comfortable with subagents

## Patterns That Work
- `xcodebuild` CLI works for building: `xcodebuild -project KB_Tracker.xcodeproj -scheme KB_Tracker -destination 'platform=iOS Simulator,id=<UDID>' build`
- `xcrun simctl install <UDID> <app-path> && xcrun simctl launch <UDID> <bundle-id>` to deploy to simulator
- iPhone 17 Pro (iOS 26.4) simulator UDID: `AB9ED8BC-4E0E-4B63-B103-844B64A759A2`
- DerivedData path: `~/Library/Developer/Xcode/DerivedData/KB_Tracker-apaozehjlnngqeectmyitkiudieh/`
- Project targets iOS 26.2, builds clean on iOS 26.4 simulator

## Patterns That Don't Work
- (none yet)

## Domain Notes
- iOS SwiftUI app with SwiftData persistence
- MVVM architecture: Models/, ViewModels/, Views/, Components/, Services/, Design/
- Two workout modes: EMOM (Every Minute On the Minute) and Rounds
- MVP ~70% complete (Phases 1-5 done, 6-8 in progress per BUILD_ORDER.md)
- Dark tactical color scheme: background #050505, surface #111111, accent white
- AudioService uses system sounds for timer beeps
- Weight range: 12-24kg in 2kg increments, single or double KB
