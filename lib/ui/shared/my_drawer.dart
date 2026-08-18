import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/mobile_data_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/exams_screen/exams_screen.dart';
import 'package:your_schedule/ui/screens/filter_screen/filter_screen.dart';
import 'package:your_schedule/ui/screens/homework_screen/homework_screen.dart';
import 'package:your_schedule/ui/screens/login_screen/welcome_screen.dart';
import 'package:your_schedule/ui/screens/messages_screen/messages_screen.dart';
import 'package:your_schedule/ui/screens/settings_screen/settings_screen.dart';
import 'package:your_schedule/ui/screens/timetable_picker_screen/timetable_picker_screen.dart';

class MyDrawer extends ConsumerWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session =
        ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final userData = session.userData;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(session.displayLabel),
            accountEmail: Text(userData.schoolName),
            currentAccountPicture: getProfileAvatar(context, ref, session),
            decoration: BoxDecoration(color: Colors.lightBlue[500]),
            //TODO: Multiple accounts
          ),
          ListTile(
            title: const Text('Stundenplan'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Stundenplan wechseln'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TimetablePickerScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Filter'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FilterScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Prüfungen'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExamsScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Hausaufgaben'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeworkScreen()),
              );
            },
          ),
          // Messages are not available for anonymous sessions — confirmed 403
          // Forbidden server-side, not something a retry/fix on our end can solve.
          if (session.loginMode != LoginMode.anonymous)
            ListTile(
              title: const Text('Nachrichten'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessagesScreen(),
                  ),
                );
              },
            ),
          Expanded(child: Container()),
          ListTile(
            title: const Text('Einstellungen'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            title: Text(
              'Logout',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () async {
              Navigator.pop(context);
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

  Widget getProfileAvatar(
    BuildContext context,
    WidgetRef ref,
    ActiveUntisSession session,
  ) {
    final fallback = CircleAvatar(
      backgroundColor: Colors.lightBlue[300],
      child: const Icon(Icons.person, color: Colors.white),
    );

    final imageUrl = ref
        .watch(accountInfoProvider(session))
        ?.user
        ?.person
        .imageUrl;
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
