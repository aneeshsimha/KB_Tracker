# Workout expansion

The app now uses one date-based runtime for built-in and custom workouts. Definitions are copied into each session; editing a preset does not rewrite history. WorkoutSession retains its original fields, with additive defaulted fields for definitions, results, source, difficulty, and export status.

## User flows

- Home: remembered setup for each built-in workout, repeat with editing, favorite presets, recovery, and the next planned workout.
- Workouts: ordered warmup, EMOM, rounds, ladder, timed work/rest, and cooldown blocks; editable movements, rep conventions, canonical loads, targets, and favorite presets.
- Runner: countdown, explicit target or actual-rep logging, pause, undo, overtime, block transitions, partial finish, and durable unsaved summaries. Blank actual reps remain unknown. Ladder rest is self-paced.
- Program: two to four selected weekdays, ABC/Press alternation or a template sequence, rescheduling, reminders, target overrides, transparent progression decisions, and approval of an owned heavier bell at the volume ceiling.
- History: filters, manual entries/corrections, comparisons, per-movement measurements, comparable progress records, CSV, and JSON backup/import.
- Settings: kg/lb display, equipment, independent cue controls, optional Health export, notifications, and iCloud synchronization.
- Shortcuts/widgets: next workout, repeat, and favorite presets. Existing active work takes precedence over a new launch.

## Data and timing

The recovery file is local to the device and is written atomically. Timers reconcile absolute deadlines after suspension; the app never creates rep counts for missed EMOM sets or uncounted timed intervals. Countdown, pauses, and time between blocks are excluded from workout duration. Background spoken audio is not guaranteed; the lock screen uses Live Activities and permitted deadline notifications.

Recorded measurements are distinct from legacy estimates. Pace comparisons require compatible prescriptions, equipment, completion, and timing. JSON import validates before writing in a separate model context and uses stable identifiers to resolve duplicate records. Health exports use a stable sync identifier and version.

## Verification

- `sh scripts/run_runtime_harness.sh` executes production runtime logic using the standalone Command Line Tools. Each run uses an isolated temporary directory and a copy of the recovery store that retains atomic writes but omits iOS file protection, which can prevent macOS CLI reads while the screen is locked. iOS services and SwiftData persistence are test doubles; simulator tests exercise the unchanged production recovery store. This harness does not substitute for iOS verification.
- `.github/workflows/ios.yml` builds the app and widget with Xcode 26.2 on macOS 26 and runs the simulator test suite.
- Swift Testing suites cover timer edge cases, progression, definition validation, metrics, backup behavior, repository idempotency, and additive migration from the legacy model.
- UI tests cover representative preset and workout flows. Signed-device verification below remains separate from simulator tests.

## Signing and device checklist

Provision these capabilities for team `YTNAUPU6L9` before a signed release:

- App Group `group.aniche-studios.KB-Tracker` for both app and widget.
- Private CloudKit container `iCloud.aniche-studios.KB-Tracker` for the app, including its production schema before distribution.
- HealthKit for the app, with user-controlled workout write authorization.

iCloud is off by default. Changing it applies at the next launch, preserving the existing `default.store` location. Verify first launch with an existing production store; enable sync, restart, and test two devices under the same Apple Account. Check offline edits, duplicate import, disabled iCloud, and subsequent synchronization. CloudKit-backed model collections have defaults and no unique constraints or required relationships.

On a signed iPhone, verify lock-screen countdown/rest/pause, notification permission denial, force-quit recovery, Health permission denial/retry, duplicate exports, widgets, Siri/Action Button launch, Dynamic Type, and VoiceOver. Simulator CI cannot certify Apple account provisioning or real HealthKit/iCloud behavior.

No Apple Watch target, custom account backend, payments, or App Store submission is included.
