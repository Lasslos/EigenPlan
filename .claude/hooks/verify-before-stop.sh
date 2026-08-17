#!/bin/bash
INPUT=$(cat)

# Required anti-loop guard: without this, a hook that always blocks
# creates an infinite loop (Claude tries to stop -> gets blocked -> tries again -> ...)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Two verification speeds: "full" (default) runs all four tiers; "light" stops after
# analyze, for quick iteration/live-debugging where a multi-minute build every turn
# is too much. Claude opts into light mode for a single upcoming turn by running
# `mkdir -p .claude && echo light > .claude/.verify-level` before finishing — see
# CLAUDE.md. The marker is one-shot: read once here, then removed, so the next turn
# defaults back to full unless explicitly set again.
LEVEL_FILE=".claude/.verify-level"
LEVEL="full"
if [ -f "$LEVEL_FILE" ]; then
  LEVEL="$(tr -d '[:space:]' < "$LEVEL_FILE")"
  rm -f "$LEVEL_FILE"
fi
if [ "$LEVEL" != "light" ]; then
  LEVEL="full"
fi

# Tier 2 (codegen) first, since analyze/build/test are meaningless against
# stale/missing .g.dart/.freezed.dart files.
if ! dart run build_runner build --delete-conflicting-outputs > /tmp/br.log 2>&1; then
  echo "build_runner failed. Fix these errors before finishing:" >&2
  tail -n 40 /tmp/br.log >&2
  exit 2
fi

# Tier 1: static analysis.
if ! flutter analyze > /tmp/analyze.log 2>&1; then
  echo "flutter analyze found issues. Fix them before finishing:" >&2
  cat /tmp/analyze.log >&2
  exit 2
fi

if [ "$LEVEL" = "light" ]; then
  exit 0
fi

# Tier 4a: offline unit/widget tests. Excludes tier 4b (tagged 'live') by default —
# dart_test.yaml skips that tag unless explicitly requested with --tags=live.
if ! flutter test > /tmp/test.log 2>&1; then
  echo "flutter test found failures. Fix them before finishing:" >&2
  tail -n 80 /tmp/test.log >&2
  exit 2
fi

# Tier 4b: live API coverage tests. --run-skipped overrides dart_test.yaml's
# always-skip for the 'live' tag; --tags=live still means "only these". Local-only
# by construction (this hook only ever runs on this machine, never in CI) and safe to
# run without credentials configured — see test/live/README.md — it then just runs a
# trivial placeholder test instead of failing.
if ! flutter test --tags=live --run-skipped > /tmp/test-live.log 2>&1; then
  echo "flutter test --tags=live found failures. Fix them before finishing:" >&2
  tail -n 80 /tmp/test-live.log >&2
  exit 2
fi

# Tier 3: build. Debug + single ABI — release would fail without a local
# signing key.properties, and this only needs to prove the app compiles.
if ! flutter build apk --debug --target-platform android-arm64 > /tmp/build.log 2>&1; then
  echo "flutter build apk --debug failed. Fix these errors before finishing:" >&2
  tail -n 60 /tmp/build.log >&2
  exit 2
fi

exit 0
