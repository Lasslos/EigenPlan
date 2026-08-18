import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'dashboard_cards_provider.g.dart';

/// The Start tab's cards, in their fixed display order — [DashboardCardVisibility]
/// tracks which of these a user has opted to hide.
enum DashboardCardType {
  schedule('Heute'),
  homework('Hausaufgaben'),
  exams('Prüfungen'),
  messages('Nachrichten'),
  announcements('Ankündigungen');

  final String label;

  const DashboardCardType(this.label);
}

/// Which [DashboardCardType]s the user has hidden from the Start tab — everything is
/// shown by default; only explicitly-disabled types end up in this set. Persisted as
/// a plain string list (enum names), matching this file's other simple on/off
/// settings rather than needing JSON.
@riverpod
class DashboardCardVisibility extends _$DashboardCardVisibility {
  @override
  Set<DashboardCardType> build() {
    final disabledNames = sharedPreferences.getStringList('disabledDashboardCards') ?? const [];
    return {
      for (final name in disabledNames)
        ?DashboardCardType.values.firstWhereOrNull((t) => t.name == name),
    };
  }

  bool isEnabled(DashboardCardType type) => !state.contains(type);

  Future<void> setEnabled(DashboardCardType type, bool enabled) async {
    final next = Set<DashboardCardType>.of(state);
    if (enabled) {
      next.remove(type);
    } else {
      next.add(type);
    }
    state = next;
    await sharedPreferences.setStringList(
      'disabledDashboardCards',
      [for (final t in next) t.name],
    );
  }
}
