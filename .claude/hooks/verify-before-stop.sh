#!/bin/bash
INPUT=$(cat)

# Required anti-loop guard: without this, a hook that always blocks
# creates an infinite loop (Claude tries to stop -> gets blocked -> tries again -> ...)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Three verification speeds: "light" stops after analyze, for quick iteration/
# live-debugging where even a build is too much; "full" (default) additionally runs
# offline tests and the debug APK build; "live" additionally runs the tier-4b live-API
# coverage suite, which hits a real school over the network (S3 attachment downloads,
# multi-week timetable/exam/homework crawl) and dominates runtime (~110s vs ~30s for
# everything else combined) — never run in CI, so it's opt-in here too. Claude opts
# into a non-default level for a single upcoming turn by running
# `mkdir -p .claude && echo light > .claude/.verify-level` (or `echo live > ...`)
# before finishing — see CLAUDE.md. The marker is one-shot: read once here, then
# removed, so the next turn defaults back to full unless explicitly set again.
LEVEL_FILE=".claude/.verify-level"
LEVEL="full"
if [ -f "$LEVEL_FILE" ]; then
  LEVEL="$(tr -d '[:space:]' < "$LEVEL_FILE")"
  rm -f "$LEVEL_FILE"
fi
case "$LEVEL" in
  light|live) ;;
  *) LEVEL="full" ;;
esac

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

# Tier 4b: live API coverage tests. Opt-in only (LEVEL=live) — see comment above on
# why this isn't part of the "full" default. --run-skipped overrides dart_test.yaml's
# always-skip for the 'live' tag; --tags=live still means "only these". Local-only
# by construction (this hook only ever runs on this machine, never in CI) and safe to
# run without credentials configured — see test/live/README.md — it then just runs a
# trivial placeholder test instead of failing.
if [ "$LEVEL" = "live" ]; then
  if ! flutter test --tags=live --run-skipped > /tmp/test-live.log 2>&1; then
    echo "flutter test --tags=live found failures. Fix them before finishing:" >&2
    tail -n 80 /tmp/test-live.log >&2
    exit 2
  fi
fi

# Tier 3: build. Debug + single ABI — release would fail without a local
# signing key.properties, and this only needs to prove the app compiles.
if ! flutter build apk --debug --target-platform android-arm64 > /tmp/build.log 2>&1; then
  echo "flutter build apk --debug failed. Fix these errors before finishing:" >&2
  tail -n 60 /tmp/build.log >&2
  exit 2
fi

exit 0
