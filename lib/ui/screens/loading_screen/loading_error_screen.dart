import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/ui/screens/login_screen/welcome_screen.dart';

class LoadingErrorScreen extends ConsumerWidget {
  final String message;
  final String? error;

  const LoadingErrorScreen({
    required this.message,
    this.error,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              SizedBox(
                height: 200,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/school_blue.png'),
                ),
              ),
              Flexible(
                flex: 4,
                child: ListView(
                  children: [
                    Text(
                      '$message\n',
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      error ?? '',
                      style: GoogleFonts.lato(fontSize: 12).copyWith(
                        color: Colors.red
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ]
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(untisSessionsProvider.notifier).clearSessions();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const WelcomeScreen();
                      },
                    ),
                  );
                },
                child: const Text('Account entfernen und neu anmelden'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
