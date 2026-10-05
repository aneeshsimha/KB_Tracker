# KB Tracker implementation status

The original MVP and the workout expansion are implemented. The former phase checklist is superseded by [the feature and verification guide](docs/FEATURE_EXPANSION.md).

## Delivered

- Shared date-based runtime for ABC, Press, Snatch, Swing, and mixed-block custom workouts.
- Workout builder, favorites, repeat/edit, equipment inventory, and kg/lb display.
- Durable active-workout recovery, pause, undo, actual-rep logging, partial finishes, and editable summaries.
- Two-to-four-day programs, ABC/Press or preset sequences, rescheduling, reminders, target overrides, and evidence-based automatic progression.
- Searchable/filterable history, manual entries and corrections, comparisons, conservative progress metrics, CSV, and validated JSON backup/import.
- Optional Health export and iCloud sync, independent cues, widgets, Shortcuts, and Live Activities.
- Runtime, model, migration, program, backup, repository, metrics, and UI regression tests; simulator CI.

Implementation work used only Sol and Terra subagents. Apple Watch remains out of scope.

## Release gates

1. Run `sh scripts/run_runtime_harness.sh` for the portable runtime checks.
2. Require the iOS verification workflow to pass for the final commit before pushing to main.
3. Complete the signed-device checklist in the feature guide, including Apple capabilities, CloudKit production schema, recovery, permissions, accessibility, and multi-device sync.

The local Xcode license must be reviewed and accepted by its owner before local simulator verification can run. The CI simulator checks do not replace signed-device verification.
