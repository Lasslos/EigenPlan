#!/usr/bin/env bash
# Builds the split-per-ABI release APKs the way they're actually published (GitHub
# Releases / IzzyOnDroid).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ! -f android/key.properties ]]; then
  echo "warning: android/key.properties not found - the release build will be unsigned." >&2
fi

# ---------------------------------------------------------------------------
# Toolchain check.
#
# Since Flutter 3.32 every build bakes FLUTTER_VERSION / FLUTTER_CHANNEL /
# FLUTTER_GIT_URL (and three more) into the AOT snapshot as compile-time
# constants - see FlutterVersion in packages/flutter/lib/src/services/
# flutter_version.dart. They cannot be overridden (flutter_tools exits if you
# try), and their values come straight from the SDK's git checkout: the channel
# is the local branch name (detached HEAD => "[user-branch]"), the git URL is
# the clone URL verbatim. A differently-shaped SDK checkout therefore silently
# changes the shipped bytes and breaks reproducible builds, which is why this
# refuses to build rather than warn. See docs/reproducible-builds.md.
# ---------------------------------------------------------------------------
expected_flutter=$(sed -n 's/^[[:space:]]*flutter:[[:space:]]*\([0-9][^[:space:]#]*\).*/\1/p' pubspec.yaml | head -n1)
if [[ -z $expected_flutter ]]; then
  echo "error: could not read 'environment: flutter:' from pubspec.yaml." >&2
  exit 1
fi

echo "==> checking toolchain"
flutter_machine=$(flutter --version --machine)
actual_flutter=$(jq -r '.frameworkVersion' <<<"$flutter_machine")
actual_channel=$(jq -r '.channel' <<<"$flutter_machine")
actual_repo=$(jq -r '.repositoryUrl' <<<"$flutter_machine")
flutter_root=$(jq -r '.flutterRoot' <<<"$flutter_machine")

toolchain_ok=1
fail() { echo "  MISMATCH: $1" >&2; toolchain_ok=0; }

[[ $actual_flutter == "$expected_flutter" ]] ||
  fail "pubspec.yaml declares Flutter $expected_flutter, but the SDK is $actual_flutter."
[[ $actual_channel == stable ]] ||
  fail "Flutter channel is '$actual_channel', expected 'stable' (goes into the APK as FLUTTER_CHANNEL)."
[[ $actual_repo == https://github.com/flutter/flutter.git ]] ||
  fail "Flutter remote is '$actual_repo', expected 'https://github.com/flutter/flutter.git' (goes into the APK as FLUTTER_GIT_URL)."

printf '  flutter   %s (%s) %s\n' "$actual_flutter" "$actual_channel" "$actual_repo"
printf '  sdk path  %s\n' "$flutter_root"
printf '  jdk       %s\n' "$(java -version 2>&1 | head -n1)"
printf '  cpus      %s\n' "$(nproc)"

if [[ $toolchain_ok -eq 0 ]]; then
  cat >&2 <<EOF

The release build was aborted because the toolchain does not match what this
release declares. To put the SDK at "$flutter_root" into the expected state:

  git -C "$flutter_root" remote set-url origin https://github.com/flutter/flutter.git
  git -C "$flutter_root" fetch --tags origin
  git -C "$flutter_root" checkout -B stable "$expected_flutter"

Use 'checkout -B stable', never a detached 'checkout $expected_flutter': the
branch name is what ends up in the APK as FLUTTER_CHANNEL.
EOF
  exit 1
fi

echo "==> flutter clean"
flutter clean
echo "==> flutter pub get"
flutter pub get

echo "==> stripping ELF build-id from the jni package's native build"
: "${PUB_CACHE:=$HOME/.pub-cache}"
shopt -s nullglob
cmake_lists=("$PUB_CACHE"/hosted/*/jni-*/src/CMakeLists.txt)
shopt -u nullglob
if [[ ${#cmake_lists[@]} -eq 0 ]]; then
  echo "error: no jni-*/src/CMakeLists.txt found under \$PUB_CACHE ($PUB_CACHE) - did 'flutter pub get' run?" >&2
  exit 1
fi
for cmake_list in "${cmake_lists[@]}"; do
  # Idempotent: 'flutter pub get' leaves an already-patched file in place, and
  # patching twice would keep prepending duplicate flags.
  if grep -q -- '--build-id=none' "$cmake_list"; then
    echo "    already patched: $cmake_list"
  else
    sed -i -e 's/-Wl,/-Wl,--build-id=none,/' "$cmake_list"
    echo "    patched: $cmake_list"
  fi
done

echo "==> flutter build apk --release --split-per-abi"
flutter build apk --release --split-per-abi

echo "==> done"
out_dir=build/app/outputs/flutter-apk
for apk in "$out_dir"/app-*-release.apk; do
  printf '%s  %s\n' "$(sha256sum "$apk" | cut -d' ' -f1)" "$apk"
done
