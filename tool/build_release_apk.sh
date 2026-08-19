#!/usr/bin/env bash
# Builds the split-per-ABI release APKs the way they're actually published (GitHub
# Releases / IzzyOnDroid).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ! -f android/key.properties ]]; then
  echo "warning: android/key.properties not found - the release build will be unsigned." >&2
fi

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
sed -i -e 's/-Wl,/-Wl,--build-id=none,/' "${cmake_lists[@]}"

echo "==> flutter build apk --release --split-per-abi"
flutter build apk --release --split-per-abi

echo "==> done"
out_dir=build/app/outputs/flutter-apk
for apk in "$out_dir"/app-*-release.apk; do
  printf '%s  %s\n' "$(sha256sum "$apk" | cut -d' ' -f1)" "$apk"
done
