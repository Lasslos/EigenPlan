import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/rpc_request/rpc_error.dart';
import 'package:your_schedule/core/untis/models/school_search/school.dart';
import 'package:your_schedule/core/untis/untis_session.dart';
import 'package:your_schedule/ui/screens/filter_screen/filter_screen.dart';
import 'package:your_schedule/ui/screens/home_screen/home_screen.dart';
import 'package:your_schedule/util/logger.dart';

/// Entry point for schools with anonymous login enabled (`login-meta`'s
/// `anonymousLoginEnabled`) — no credentials are collected at all.
class AnonymousLoginScreen extends ConsumerStatefulWidget {
  final School school;

  const AnonymousLoginScreen({required this.school, super.key});

  @override
  ConsumerState createState() => _AnonymousLoginScreenState();
}

class _AnonymousLoginScreenState extends ConsumerState<AnonymousLoginScreen> {
  var isLoading = false;
  String message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.school.displayName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Diese Schule erlaubt einen anonymen Zugriff ohne Anmeldedaten. '
                            'Manche Funktionen (z. B. eigene Nachrichten) sind dann eingeschränkt.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: isLoading
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: SizedBox(
                                      height: 48,
                                      child: Center(child: LinearProgressIndicator()),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _continueAnonymously,
                                    child: const Text('Als Gast fortfahren'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    label: const Text('Zurück'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continueAnonymously() async {
    setState(() {
      isLoading = true;
    });

    var connectivityResult = await ref.read(connectivityProvider.future);
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        message = 'Keine Internetverbindung';
        isLoading = false;
      });
      return;
    }

    UntisSession session = UntisSession.inactive(
      school: widget.school,
      loginMode: LoginMode.anonymous,
    );

    try {
      session = await activateSession(ref, session);
      ref.read(untisSessionsProvider.notifier).addSession(session);

      Navigator.pushAndRemoveUntil(
        //ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      Navigator.push(
        //ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => const FilterScreen()),
      );
    } on RPCError catch (e) {
      setState(() {
        message = e.message;
      });
    } on ClientException catch (e, s) {
      getLogger().e('ClientException while logging in anonymously', error: e, stackTrace: s);
      setState(() {
        message = e.toString();
      });
    } catch (e, s) {
      getLogger().e('Unknown error while logging in anonymously', error: e, stackTrace: s);
      setState(() {
        message = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
