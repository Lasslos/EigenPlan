import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/custom_subject_colors.dart';
import 'package:your_schedule/core/provider/mobile_data_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/settings/dashboard_cards_provider.dart';
import 'package:your_schedule/settings/grid_cell_height_provider.dart';
import 'package:your_schedule/settings/sentry_provider.dart';
import 'package:your_schedule/settings/theme_provider.dart';
import 'package:your_schedule/ui/screens/filter_screen/filter_screen.dart';
import 'package:your_schedule/ui/screens/login_screen/welcome_screen.dart';
import 'package:your_schedule/ui/screens/timetable_screen/widgets/grid_entry_widget.dart';
import 'package:your_schedule/ui/screens/timetable_screen/widgets/timegrid_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session =
        ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          ListTile(
            leading: _ProfileAvatar(session: session),
            title: Text(session.displayLabel),
            subtitle: Text(session.userData.schoolName),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              bottom: 8.0,
            ),
            child: Text(
              'Stundenplan',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withAlpha(200),
              ),
            ),
          ),
          ListTile(
            title: const Text('Filter'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FilterScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Zeitblock-Höhe'),
            subtitle: Text('${ref.watch(gridCellHeightSettingProvider)} px'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const _GridCellHeightDialog(),
              );
            },
          ),
          ListTile(
            title: const Text('Farben zurücksetzen'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Farben zurücksetzen'),
                  content: const Text(
                    'Möchtest du wirklich alle Farben der Fächer zurücksetzen?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Abbrechen'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ref.read(customSubjectColorsProvider.notifier).reset();
                      },
                      child: const Text('Zurücksetzen'),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              bottom: 8.0,
            ),
            child: Text(
              'Anzeige',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withAlpha(200),
              ),
            ),
          ),
          ListTile(
            title: const Text('Design'),
            subtitle: Text(switch (ref.watch(themeSettingProvider)) {
              ThemeMode.system => 'Systemvorgabe',
              ThemeMode.light => 'Hell',
              ThemeMode.dark => 'Dunkel',
            }),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Design'),
                  content: RadioGroup<ThemeMode>(
                    groupValue: ref.watch(themeSettingProvider),
                    onChanged: (value) {
                      ref.read(themeSettingProvider.notifier).setTheme(value!);
                      Navigator.of(context).pop();
                    },
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<ThemeMode>(
                          title: Text('Systemvorgabe'),
                          value: ThemeMode.system,
                        ),
                        RadioListTile<ThemeMode>(
                          title: Text('Hell'),
                          value: ThemeMode.light,
                        ),
                        RadioListTile<ThemeMode>(
                          title: Text('Dunkel'),
                          value: ThemeMode.dark,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Startbildschirm'),
            subtitle: const Text('Karten ein-/ausblenden'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const _DashboardCardsDialog(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              bottom: 8.0,
            ),
            child: Text(
              'Sonstiges',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withAlpha(200),
              ),
            ),
          ),
          ListTile(
            title: const Text('Fehlerberichte senden'),
            subtitle: ref.watch(sentrySettingsProvider) == true
                ? const Text('Aktiviert')
                : const Text('Deaktiviert'),
            onTap: () async {
              final consent = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('Fehlerberichte senden?'),
                    content: const Text(
                      'EigenPlan wird kontinuierlich verbessert. Wir verwenden Sentry, um Fehlerberichte zu sammeln. '
                      'Fehlerberichte helfen uns dabei, Probleme zu erkennen und zu beheben. Dafür benötigen wir jedoch deine Zustimmung. '
                      'Du kannst deine Zustimmung jederzeit in den Einstellungen widerrufen. Möchtest du Fehlerberichte senden?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                        },
                        child: const Text('Ja'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
                        },
                        child: const Text('Nein'),
                      ),
                    ],
                  );
                },
              );

              if (consent != null && context.mounted) {
                await ref.read(sentrySettingsProvider.notifier).setSentryEnabled(consent);
              }
            },
          ),
          ListTile(
            title: Text(
              'Logout',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () {
              ref
                  .read(untisSessionsProvider.notifier)
                  .markSessionForRemoval(session);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardCardsDialog extends ConsumerWidget {
  const _DashboardCardsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disabled = ref.watch(dashboardCardVisibilityProvider);
    return AlertDialog(
      title: const Text('Startbildschirm'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in DashboardCardType.values)
            CheckboxListTile(
              title: Text(type.label),
              value: !disabled.contains(type),
              onChanged: (value) {
                ref
                    .read(dashboardCardVisibilityProvider.notifier)
                    .setEnabled(type, value ?? true);
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fertig'),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends ConsumerWidget {
  const _ProfileAvatar({required this.session});

  final ActiveUntisSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = CircleAvatar(
      backgroundColor: Colors.lightBlue[300],
      child: const Icon(Icons.person, color: Colors.white),
    );

    final imageUrl = ref.watch(accountInfoProvider(session))?.user?.person.imageUrl;
    if (imageUrl == null) {
      return fallback;
    }

    if (session.loginMode == LoginMode.anonymous) {
      return CircleAvatar(
        backgroundColor: Colors.lightBlue[300],
        foregroundImage: NetworkImage(
          imageUrl,
          headers: session.restAuthHeaders(null),
        ),
        onForegroundImageError: (_, _) {},
        child: const Icon(Icons.person, color: Colors.white),
      );
    }

    return FutureBuilder<AuthToken>(
      future: ref.read(authTokenProvider(session).future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return fallback;
        }
        return CircleAvatar(
          backgroundColor: Colors.lightBlue[300],
          foregroundImage: NetworkImage(
            imageUrl,
            headers: session.restAuthHeaders(snapshot.data),
          ),
          onForegroundImageError: (_, _) {},
          child: const Icon(Icons.person, color: Colors.white),
        );
      },
    );
  }
}

/// Picks [GridCellHeightSetting] with a slider over a live preview of a single period,
/// rendered with the real timetable widgets at the height being chosen — a raw pixel
/// count means nothing on its own, and the preview is what makes it mean something.
class _GridCellHeightDialog extends ConsumerStatefulWidget {
  const _GridCellHeightDialog();

  @override
  ConsumerState<_GridCellHeightDialog> createState() =>
      _GridCellHeightDialogState();
}

class _GridCellHeightDialogState extends ConsumerState<_GridCellHeightDialog> {
  late double _height = ref
      .read(gridCellHeightSettingProvider)
      .toDouble();

  void _setHeight(double height) {
    setState(() => _height = height);
    ref
        .read(gridCellHeightSettingProvider.notifier)
        .setGridCellHeight(height.round());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Zeitblock-Höhe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed box so only the preview cell grows/shrinks while dragging — the
          // dialog itself must not resize under the user's finger. Sized for the
          // largest the preview ever gets: the cell at its maximum, plus the two
          // 1px dividers _GridCellHeightPreview draws around it.
          SizedBox(
            height: gridCellHeightMax + _GridCellHeightPreview.dividerHeight * 2,
            child: Align(
              alignment: Alignment.topCenter,
              child: _GridCellHeightPreview(height: _height),
            ),
          ),
          Slider(
            min: gridCellHeightMin.toDouble(),
            max: gridCellHeightMax.toDouble(),
            value: _height,
            label: '${_height.round()} px',
            // Only commit once the gesture ends: the preview follows every frame, but
            // SharedPreferences is written once per drag rather than per pixel.
            onChanged: (value) => setState(() => _height = value),
            onChangeEnd: (value) => _setHeight(value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _setHeight(gridCellHeightDefault.toDouble()),
          child: const Text('Standard'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fertig'),
        ),
      ],
    );
  }
}

/// One dummy period rendered exactly the way the timetable renders it, at [height]
/// pixels. A median-length period is `gridCellHeight` pixels tall in the real grid (see
/// `timegrid_widget.dart`), so the preview needs no scaling of its own — and it borrows
/// the user's own median period for the time column, so the times shown are real.
class _GridCellHeightPreview extends ConsumerWidget {
  const _GridCellHeightPreview({required this.height});

  final double height;

  /// Thickness of the rules drawn above and below the cell, mirroring the ones the
  /// real time grid draws around every period.
  static const double dividerHeight = 1;

  static GridEntryPositionItem _position(
    String type,
    String shortName,
    String longName,
  ) => GridEntryPositionItem(
    current: GridEntryPositionElement(
      type: type,
      status: 'REGULAR',
      shortName: shortName,
      longName: longName,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var timeGrid = ref.watch(
      selectedUntisSessionProvider.select(
        (value) => (value as ActiveUntisSession).userData.timeGrid,
      ),
    );
    var period = timeGrid.medianPeriod;
    var day = DateTime.now();

    var entry = GridEntry(
      duration: GridEntryDuration(
        start: DateTime(
          day.year,
          day.month,
          day.day,
          period.startTime.hour,
          period.startTime.minute,
        ),
        end: DateTime(
          day.year,
          day.month,
          day.day,
          period.endTime.hour,
          period.endTime.minute,
        ),
      ),
      type: 'NORMAL_TEACHING_PERIOD',
      status: 'REGULAR',
      position1: [_position('SUBJECT', 'Mathe', 'Mathematik')],
      position2: [_position('TEACHER', 'MUS', 'Frau Muster')],
      position3: [_position('ROOM', 'A101', 'Raum A101')],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(thickness: 0.7, height: dividerHeight),
        SizedBox(
          height: height,
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: TimeGridColumnElement(entry: period),
              ),
              const VerticalDivider(width: 1, thickness: 0.7),
              const SizedBox(width: 4),
              // The card would otherwise push GridEntryDetailsView out of the dialog.
              Expanded(
                child: IgnorePointer(
                  child: GridEntryWidget(entry: entry, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const Divider(thickness: 0.7, height: dividerHeight),
      ],
    );
  }
}
