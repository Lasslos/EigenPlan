# Reproducible builds

EigenPlan aims to be [reproducible](https://izzyondroid.org/about/security/ReproducibleBuilds/):
a rebuilder that starts from the tagged source should end up with an APK that is byte-identical to
the published one, apart from the signature. That is only possible if the rebuilder's build
environment matches the one the release was built in, so this page records that environment exactly —
and, more importantly, *why* each item matters.

Tracking issue: [#23](https://github.com/Lasslos/your_schedule/issues/23).

## The build environment

|                 | value                                                                 | how it is enforced                                 |
|-----------------|-----------------------------------------------------------------------|----------------------------------------------------|
| Flutter         | the version in `pubspec.yaml` → `environment: flutter:`               | checked by `tool/build_release_apk.sh`             |
| Flutter channel | `stable` (a local branch literally named `stable`)                    | checked by `tool/build_release_apk.sh`             |
| Flutter remote  | `https://github.com/flutter/flutter.git` (**with** the `.git` suffix) | checked by `tool/build_release_apk.sh`             |
| JDK             | Temurin 17 (currently `17.0.20.1+1`)                                  | `sourceCompatibility`/`targetCompatibility` = 17   |
| Gradle          | 9.7.0                                                                 | `android/gradle/wrapper/gradle-wrapper.properties` |
| AGP             | 9.2.0                                                                 | `android/settings.gradle.kts`                      |
| Kotlin          | 2.4.10                                                                | `android/settings.gradle.kts`                      |
| Build command   | `flutter build apk --release --split-per-abi`                         | `tool/build_release_apk.sh`                        |

`tool/build_release_apk.sh` prints the JDK version and CPU count of every release build, so the
release log records what was actually used.

Set up a matching Flutter SDK like this — the tag pins the commit, the branch *name* is what ends up
inside the APK:

```shell
git clone https://github.com/flutter/flutter.git
git -C flutter checkout -B stable <version>   # e.g. 3.47.4
```

Do **not** use a detached `git checkout <version>`; see the next section for why.

## Why these three Flutter properties are load-bearing

Since **Flutter 3.32**, every `flutter build` injects six dart-defines:

```
FLUTTER_VERSION, FLUTTER_CHANNEL, FLUTTER_GIT_URL,
FLUTTER_FRAMEWORK_REVISION, FLUTTER_ENGINE_REVISION, FLUTTER_DART_VERSION
```

`FlutterVersion` (`packages/flutter/lib/src/services/flutter_version.dart`) reads them with
`const String.fromEnvironment(...)`, so they are **compile-time constants baked into the AOT
snapshot**, i.e. into `lib/<abi>/libapp.so`. They cannot be overridden: `flutter_tools` exits with an
error if any of them is passed via `--dart-define`, `--dart-define-from-file`, or the environment.

Their values come straight from the SDK's git checkout
(`packages/flutter_tools/lib/src/version.dart`):

- **`FLUTTER_CHANNEL`** is `git symbolic-ref --short HEAD`, replaced by the literal string
  `[user-branch]` when the branch is not an official channel name *or when HEAD is detached*. So
  `git clone -b <tag>` or `git checkout <tag>` produces `[user-branch]`, while an SDK installed from
  the official tar.xz produces `stable`.
- **`FLUTTER_GIT_URL`** is `git ls-remote --get-url <remote>`, i.e. the clone URL *verbatim* —
  cloning `…/flutter` and cloning `…/flutter.git` give different strings.

Two SDKs at the very same commit therefore produce different `libapp.so` bytes if they were obtained
differently. This was the cause of the `libapp.so` mismatch in #23.

### Different approaches and their results

| approach                         | version you get          | `FLUTTER_CHANNEL` |
|----------------------------------|--------------------------|-------------------|
| `git switch stable`              | 3.48.0 — a moving target | `stable`          |
| `git checkout 3.47.4` (detached) | 3.47.4                   | `[user-branch]`   |
| `git checkout -B stable 3.47.4`  | 3.47.4                   | `stable`          |

## Ruled out: build parallelism

The `classes.dex` / `classes2.dex` mismatch in #23 looks like R8's horizontal class merging numbering
merged classes (`$r8$classId`) in a different order — diffoscope marks every hunk "Ordering
differences only" — and the obvious suspect was the thread count, since AGP sizes the R8/D8 thread
pool from Gradle's worker count (`R8D8ThreadPoolBuildService`), which defaults to the number of CPUs
on the build machine.

**That is not the cause.** Measured with `tool/rb_compare.sh`, six release builds of the same tree:

| variation                                                         | result         |
|-------------------------------------------------------------------|----------------|
| two builds, same environment                                      | byte-identical |
| 12 CPUs vs. `taskset -c 0-3`                                      | byte-identical |
| `org.gradle.workers.max` / `android.r8.threadPoolSize` = 12 vs. 1 | byte-identical |

All six produced the same APK (`c7aa3811…`). The 12-vs-1-thread builds took 156 s and 249 s, so the
setting demonstrably took effect — the output simply does not depend on it. Pinning the worker count
was therefore *not* added: it would cost build time while fixing nothing.

The build is locally deterministic, which means the remaining `classes*.dex` difference is caused by
something that differs *between the two machines* rather than by nondeterminism. The parts of the
toolchain the repository does **not** pin, and hence the open suspects, are:

- the exact JDK build (Temurin `17.0.20.1+1` here),
- the installed Android SDK platform revision for `compileSdk` 37 (its `android.jar` is an R8 input,
  so a different revision can change merging decisions) and the build-tools revision.

`assets/dexopt/baseline.prof{,m}` is derived from the dex output and should follow whatever fixes
it.

## Why the `jni` linker flag is patched

The `jni` package's `CMakeLists.txt` links without `--build-id=none`, so `libdartjni.so` embeds an
ELF build ID that differs per build. `tool/build_release_apk.sh` patches the file in the pub cache
before building (idempotently — the pub cache keeps the patch across `flutter pub get`).

## Checking reproducibility locally

`tool/rb_compare.sh` builds the release APK twice and reports which zip entries differ, the same way
a rebuilder's check does. This makes it possible to test a hypothesis in minutes instead of shipping
a release and waiting for a rebuild.

```shell
tool/rb_compare.sh                              # two builds, identical environment
tool/rb_compare.sh --second 'taskset -c 0-3'    # vary exactly one thing: the CPU count
tool/rb_compare.sh --a old.apk --b new.apk      # just compare two existing APKs
```

It stops the Gradle and Kotlin daemons before each build, since a reused daemon keeps the environment
of whoever started it and would quietly ignore a `taskset` prefix. Entries with equal uncompressed
sizes but different CRCs are the signature of an ordering-only difference.

To test a rebuilder-shaped Flutter SDK, clone a second SDK the way they do, point
`android/local.properties`' `flutter.sdk` (and `PATH`) at it, and compare:

```shell
git clone https://github.com/flutter/flutter /tmp/flutter-rebuilder
git -C /tmp/flutter-rebuilder checkout <version>     # detached, on purpose
```

Requires `jq`, `taskset` (util-linux) and `unzip`.
