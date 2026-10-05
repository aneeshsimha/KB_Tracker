#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SWIFTC=/Library/Developer/CommandLineTools/usr/bin/swiftc
OUTPUT=${TMPDIR:-/tmp}/kb-tracker-runtime-harness
MODULE_CACHE=${TMPDIR:-/tmp}/kb-tracker-clang-cache
SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
PURE_DEFINITION=${TMPDIR:-/tmp}/kb-tracker-workout-definition.swift

mkdir -p "$MODULE_CACHE"
sed '/@Model final class WorkoutTemplate/,$d' \
  "$ROOT/KB_Tracker/Models/WorkoutDefinition.swift" > "$PURE_DEFINITION"

CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" "$SWIFTC" \
  -sdk "$SDK" \
  -target arm64-apple-macosx26.0 \
  "$ROOT/KB_Tracker/Models/Enums.swift" \
  "$ROOT/KB_Tracker/Models/WorkoutParameters.swift" \
  "$ROOT/KB_Tracker/Models/WorkoutConfig.swift" \
  "$PURE_DEFINITION" \
  "$ROOT/KB_Tracker/Services/ActiveWorkoutStore.swift" \
  "$ROOT/KB_Tracker/Services/WorkoutRuntime.swift" \
  "$ROOT/KB_Tracker/Services/ProgramService.swift" \
  "$ROOT/scripts/runtime_harness_support.swift" \
  "$ROOT/scripts/runtime_harness.swift" \
  -o "$OUTPUT"

KB_ACTIVE_WORKOUT_PATH=${TMPDIR:-/tmp}/kb-tracker-active-workout.json "$OUTPUT"
