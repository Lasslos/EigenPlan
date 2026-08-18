import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/custom_subject_colors.dart';
import 'package:your_schedule/core/provider/mobile_data_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/settings/dashboard_cards_provider.dart';
import 'package:your_schedule/settings/sentry_provider.dart';
import 'package:your_schedule/settings/theme_provider.dart';
import 'package:your_schedule/ui/screens/filter_screen/filter_screen.dart';
import 'package:your_schedule/ui/screens/login_screen/welcome_screen.dart';

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
