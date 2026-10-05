#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SWIFTC=/Library/Developer/CommandLineTools/usr/bin/swiftc
SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
RUN_DIR=$(mktemp -d /tmp/kb-runtime-harness.XXXXXX)
OUTPUT=$RUN_DIR/runtime-harness
MODULE_CACHE=$RUN_DIR/module-cache
PURE_DEFINITION=$RUN_DIR/workout-definition.swift
HARNESS_STORE=$RUN_DIR/active-workout-store.swift
CHECKPOINT=$RUN_DIR/active-workout.json

cleanup() {
  case "$RUN_DIR" in
    /tmp/kb-runtime-harness.*) rm -rf "$RUN_DIR" ;;
  esac
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$MODULE_CACHE"
sed '/@Model final class WorkoutTemplate/,$d' \
  "$ROOT/KB_Tracker/Models/WorkoutDefinition.swift" > "$PURE_DEFINITION"
# Data's iOS complete-file-protection option can make a macOS CLI artifact
# unreadable while the screen is locked. The harness retains atomic writes but
# removes only that platform-specific protection option in its temporary copy.
sed 's/\[\.atomic, \.completeFileProtectionUnlessOpen\]/[.atomic]/' \
  "$ROOT/KB_Tracker/Services/ActiveWorkoutStore.swift" > "$HARNESS_STORE"

CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" "$SWIFTC" \
  -sdk "$SDK" \
  -target arm64-apple-macosx26.0 \
  "$ROOT/KB_Tracker/Models/Enums.swift" \
  "$ROOT/KB_Tracker/Models/WorkoutParameters.swift" \
  "$ROOT/KB_Tracker/Models/WorkoutConfig.swift" \
  "$PURE_DEFINITION" \
  "$HARNESS_STORE" \
  "$ROOT/KB_Tracker/Services/WorkoutRuntime.swift" \
  "$ROOT/KB_Tracker/Services/ProgramService.swift" \
  "$ROOT/scripts/runtime_harness_support.swift" \
  "$ROOT/scripts/runtime_harness.swift" \
  -o "$OUTPUT"

KB_ACTIVE_WORKOUT_PATH="$CHECKPOINT" "$OUTPUT"
