import 'package:flutter/material.dart';
import 'package:your_schedule/ui/screens/login_screen/pick_login_method_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Center(child: WelcomeWidget()),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PickLoginMethodScreen()),
                        );
                      },
                      label: const Text('Weiter'),
                      icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomeWidget extends StatelessWidget {
  const WelcomeWidget({super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height / 5,
        ),
        margin: const EdgeInsets.symmetric(vertical: 32),
        child: Image.asset(
          'assets/school_blue.png',
        ),
      ),
      Text(
        'Willkommen bei\nEigenPlan für Untis!',
        style: Theme.of(context).textTheme.displaySmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      Text(
        'Dein Stundenplan ist nur noch ein paar Klicks entfernt.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ],
  );
}
