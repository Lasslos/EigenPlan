import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:your_schedule/core/provider/custom_subject_colors.dart';
import 'package:your_schedule/core/provider/mobile_data_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/settings/sentry_provider.dart';
import 'package:your_schedule/settings/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session =
        ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final mobileData = ref.watch(accountInfoProvider(session));

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              bottom: 8.0,
            ),
            child: Text(
              'Design',
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
          if (mobileData != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: 16.0,
                left: 16.0,
                right: 16.0,
                bottom: 8.0,
              ),
              child: Text(
                'Konto',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withAlpha(200),
                ),
              ),
            ),
            ListTile(
              title: const Text('Schule'),
              subtitle: Text(mobileData.tenant.displayName),
            ),
            if (mobileData.schoolYear != null)
              ListTile(
                title: Text(mobileData.schoolYear!.name),
                subtitle: Text(
                  '${intl.DateFormat('dd.MM.yyyy').format(mobileData.schoolYear!.dateRange.start)} – '
                  '${intl.DateFormat('dd.MM.yyyy').format(mobileData.schoolYear!.dateRange.end)}',
                ),
              ),
          ],
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
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Fehlerberichte senden?'),
                    content: const Text(
                      'EigenPlan wird kontinuierlich verbessert. Wir verwenden Sentry, um Fehlerberichte zu sammeln. '
                      'Fehlerberichte helfen uns dabei, Probleme zu erkennen und zu beheben. Dafür benötigen wir jedoch deine Zustimmung. '
                      'Du kannst deine Zustimmung jederzeit in den Einstellungen wiederrufen. Die Einstellung wird mit einem App-Neustart aktiv. Möchtest du Fehlerberichte senden?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          ref
                              .read(sentrySettingsProvider.notifier)
                              .setSentryEnabled(true);
                          Navigator.pop(context);
                        },
                        child: const Text('Ja'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(sentrySettingsProvider.notifier)
                              .setSentryEnabled(false);
                          Navigator.pop(context);
                        },
                        child: const Text('Nein'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
