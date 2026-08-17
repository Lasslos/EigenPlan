#!/bin/bash
INPUT=$(cat)

# Required anti-loop guard: without this, a hook that always blocks
# creates an infinite loop (Claude tries to stop -> gets blocked -> tries again -> ...)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

# build_runner first, since analyze is meaningless against stale/missing .g.dart files
if ! dart run build_runner build --delete-conflicting-outputs > /tmp/br.log 2>&1; then
  echo "build_runner failed. Fix these errors before finishing:" >&2
  tail -n 40 /tmp/br.log >&2
  exit 2
fi

if ! flutter analyze > /tmp/analyze.log 2>&1; then
  echo "flutter analyze found issues. Fix them before finishing:" >&2
  cat /tmp/analyze.log >&2
  exit 2
fi

exit 0
