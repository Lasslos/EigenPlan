import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/filter_screen/filter_screen.dart';
import 'package:your_schedule/ui/screens/login_screen/welcome_screen.dart';
import 'package:your_schedule/ui/screens/settings_screen/settings_screen.dart';
import 'package:your_schedule/ui/screens/messages_screen/messages_screen.dart';

class MyDrawer extends ConsumerWidget {
  const MyDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final userData = session.userData;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(session.username),
            accountEmail: Text(userData.schoolName),
            currentAccountPicture: getProfileAvatar(context, ref),
            decoration: BoxDecoration(
              color: Colors.lightBlue[500],
            ),
            //TODO: Multiple accounts
          ),
          ListTile(
            title: const Text("Stundenplan"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("Filter"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FilterScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text("Nachrichten"),
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
            title: const Text("Einstellungen"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: Text(
              "Logout",
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () async {
              Navigator.pop(context);
              ref.read(untisSessionsProvider.notifier).markSessionForRemoval(session);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const WelcomeScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget getProfileAvatar(BuildContext context, WidgetRef ref) {
    return CircleAvatar(
      backgroundColor: Colors.lightBlue[300],
      child: const Icon(Icons.person, color: Colors.white),
    );
  }
}
