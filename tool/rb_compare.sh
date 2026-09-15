#!/usr/bin/env bash
# Local reproducible-build harness: builds the release APK twice and reports which
# zip entries differ, the same way IzzyOnDroid's rebuild check does - so an RB
# hypothesis can be tested locally instead of costing a release plus a rebuild.
#
#   tool/rb_compare.sh                              # two builds, identical environment
#   tool/rb_compare.sh --second 'taskset -c 0-3'    # vary one variable in build B
#   tool/rb_compare.sh --a old.apk --b new.apk      # just compare two existing APKs
#
# See docs/reproducible-builds.md.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

abi=arm64-v8a
first_prefix=''
second_prefix=''
apk_a=''
apk_b=''
stop_daemons=1

usage() {
  sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
  cat <<'USAGE'

Options:
  --abi <abi>        ABI to compare (default: arm64-v8a)
  --first <cmd>      command prefix for build A (e.g. 'taskset -c 0-3')
  --second <cmd>     command prefix for build B
  --a <apk>          skip build A, use this APK
  --b <apk>          skip build B, use this APK
  --keep-daemons     do not stop the Gradle/Kotlin daemons between builds
  -h, --help         this text
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --abi) abi=$2; shift 2 ;;
    --first) first_prefix=$2; shift 2 ;;
    --second) second_prefix=$2; shift 2 ;;
    --a) apk_a=$2; shift 2 ;;
    --b) apk_b=$2; shift 2 ;;
    --keep-daemons) stop_daemons=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

# Not under build/: tool/build_release_apk.sh runs 'flutter clean', which would
# delete build A again while build B is being produced.
work=.rb-compare
built_apk="build/app/outputs/flutter-apk/app-$abi-release.apk"

# A running daemon is reused across builds and keeps the environment of whoever
# started it - including CPU affinity, which would silently defeat a
# '--second taskset -c 0-3' experiment.
stop_build_daemons() {
  echo "==> stopping Gradle/Kotlin daemons"
  pkill -f 'org.gradle.launcher.daemon.bootstrap.GradleDaemon' 2>/dev/null || true
  pkill -f 'org.jetbrains.kotlin.daemon.KotlinCompileDaemon' 2>/dev/null || true
  # Bracketed so the waiting shell's own command line does not match the pattern.
  timeout 20 bash -c 'while pgrep -f "org[.]gradle[.]launcher[.]daemon[.]bootstrap[.]GradleDaemon" >/dev/null; do sleep 0.2; done' || true
}

build_into() {
  local label=$1 prefix=$2 dest=$3
  echo
  echo "=============================================================="
  echo "==> build $label${prefix:+ (prefix: $prefix)}"
  echo "=============================================================="
  [[ $stop_daemons -eq 1 ]] && stop_build_daemons
  # Word-splitting of $prefix is intentional: it is a command prefix, not a path.
  # shellcheck disable=SC2086
  ${prefix:-} tool/build_release_apk.sh
  if [[ ! -f $built_apk ]]; then
    echo "error: expected $built_apk after the build - wrong --abi?" >&2
    exit 1
  fi
  cp "$built_apk" "$dest"
}

# Entries that legitimately differ between two signings of identical content.
is_signature_entry() {
  [[ $1 == META-INF/MANIFEST.MF ]] && return 0
  [[ $1 =~ ^META-INF/[^/]+\.(RSA|DSA|EC|SF)$ ]]
}

# Prints "<sha256>  <entry>" for every file in the APK, sorted by entry name.
hash_entries() {
  local apk=$1 dir=$2
  rm -rf "$dir"
  mkdir -p "$dir"
  unzip -q -o "$apk" -d "$dir"
  (cd "$dir" && find . -type f | sed 's|^\./||' | LC_ALL=C sort | xargs -d '\n' -r sha256sum)
}

mkdir -p "$work"

if [[ -n $apk_a ]]; then cp "$apk_a" "$work/A.apk"; else build_into A "$first_prefix" "$work/A.apk"; fi
if [[ -n $apk_b ]]; then cp "$apk_b" "$work/B.apk"; else build_into B "$second_prefix" "$work/B.apk"; fi

hash_entries "$work/A.apk" "$work/A" > "$work/A.sha256"
hash_entries "$work/B.apk" "$work/B" > "$work/B.sha256"

echo
echo "=============================================================="
echo "==> comparison"
echo "=============================================================="
printf 'A: %s  (%s bytes)\n' "$(sha256sum "$work/A.apk" | cut -d' ' -f1)" "$(stat -c%s "$work/A.apk")"
printf 'B: %s  (%s bytes)\n' "$(sha256sum "$work/B.apk" | cut -d' ' -f1)" "$(stat -c%s "$work/B.apk")"
echo

# sha256sum prints "<hash>  <name>"; split on the two-space separator so entry
# names containing spaces survive.
mapfile -t differing < <(
  awk '
    { name = substr($0, index($0, "  ") + 2); hash = $1 }
    NR == FNR { a[name] = hash; next }
    { b[name] = hash }
    END {
      for (n in a) if (!(n in b) || a[n] != b[n]) print n
      for (n in b) if (!(n in a)) print n
    }
  ' "$work/A.sha256" "$work/B.sha256" | LC_ALL=C sort
)

signature_only=()
real=()
for entry in "${differing[@]:-}"; do
  [[ -z $entry ]] && continue
  if is_signature_entry "$entry"; then signature_only+=("$entry"); else real+=("$entry"); fi
done

if [[ ${#signature_only[@]} -gt 0 ]]; then
  echo "Signature entries differing (expected, ignored):"
  printf '  %s\n' "${signature_only[@]}"
  echo
fi

if [[ ${#real[@]} -eq 0 ]]; then
  echo "REPRODUCIBLE: every non-signature entry is byte-identical."
  exit 0
fi

echo "NOT REPRODUCIBLE: ${#real[@]} entry/entries differ."
echo
printf '%-44s %12s %12s %10s %10s\n' 'entry' 'size-A' 'size-B' 'crc-A' 'crc-B'
printf '%-44s %12s %12s %10s %10s\n' '--------------------------------------------' '------------' '------------' '----------' '----------'
zipinfo_field() { # <apk> <entry> -> "<uncompressed size> <crc>"
  unzip -v "$1" "$2" 2>/dev/null | awk -v e="$2" '$NF == e {print $1, $7}'
}
for entry in "${real[@]}"; do
  read -r size_a crc_a <<<"$(zipinfo_field "$work/A.apk" "$entry")"
  read -r size_b crc_b <<<"$(zipinfo_field "$work/B.apk" "$entry")"
  printf '%-44s %12s %12s %10s %10s\n' "$entry" "${size_a:-?}" "${size_b:-?}" "${crc_a:-?}" "${crc_b:-?}"
done
echo
echo "Equal sizes with differing CRCs usually mean an ordering-only difference."
echo "Unpacked trees for further digging: $work/A and $work/B"
exit 1
