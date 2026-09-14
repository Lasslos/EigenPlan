import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/utils.dart';

part 'clock_provider.g.dart';

/// Lands just *after* the next whole minute rather than exactly on it, so the rebuild
/// triggered there reads the new minute instead of racing the boundary.
const _epsilon = Duration(milliseconds: 50);

/// The instant the minute after [now] begins, plus [_epsilon].
///
/// Split out as a pure function so the boundary maths is testable without waiting on real
/// timers — see `test/unit/util/clock_test.dart`.
DateTime nextMinuteBoundary(DateTime now) {
  final startOfMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
  return startOfMinute.add(const Duration(minutes: 1) + _epsilon);
}

/// The current wall-clock minute, truncated to `:00` seconds, re-derived just after every
/// minute boundary and whenever the app is resumed.
///
/// Widgets can't observe the passage of time on their own — they rebuild when a watched
/// dependency changes, and wall-clock time isn't one — so anything whose output depends on
/// "now" has to watch this (or [today]) instead of calling `DateTime.now()` in `build`.
/// Without it a screen that stays mounted (all three tabs do: `MainShell` keeps them in an
/// `IndexedStack`) keeps rendering whatever "now" meant when it last happened to rebuild.
///
/// Truncating to the minute is what makes this cheap: a countdown or a date label can't
/// show more resolution than that, so one rebuild per minute is all any consumer needs, and
/// listeners are only notified when the value actually changes.
///
/// The timer alone isn't enough: Android is free to freeze the isolate while the app is
/// backgrounded, so it may fire late or not at all. `MyApp` invalidates this provider on
/// resume — the binding that observing the lifecycle needs only exists in the widget layer,
/// and keeping it out of here means this provider still works in a bare `ProviderContainer`.
@riverpod
DateTime currentMinute(Ref ref) {
  final now = DateTime.now();

  final timer = Timer(
    nextMinuteBoundary(now).difference(now),
    ref.invalidateSelf,
  );
  ref.onDispose(timer.cancel);

  return DateTime(now.year, now.month, now.day, now.hour, now.minute);
}

/// Today's calendar date, kept current as the day rolls over.
///
/// Derived from [currentMinute] so a single timer serves the whole app. [Date] compares by
/// calendar day, so watchers of this provider are only notified at midnight even though the
/// value behind it is recomputed every minute.
@riverpod
Date today(Ref ref) => Date(ref.watch(currentMinuteProvider));
