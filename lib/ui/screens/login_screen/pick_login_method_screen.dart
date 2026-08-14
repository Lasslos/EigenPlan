import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/ui/screens/login_screen/manual_login_screen.dart';
import 'package:your_schedule/ui/screens/login_screen/scan_qr_code_screen.dart';
import 'package:your_schedule/ui/screens/login_screen/search_school_screen.dart';

class PickLoginMethodScreen extends ConsumerStatefulWidget {
  const PickLoginMethodScreen({super.key});

  @override
  ConsumerState createState() => _PickLoginMethodScreenState();
}

class _PickLoginMethodScreenState extends ConsumerState<PickLoginMethodScreen> {
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
                            'Log-In-Methode',
                            style: Theme
                                .of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: searchSchool,
                            icon: const Icon(Icons.search),
                            label: const Text('Schule oder Adresse suchen'),
                          ),
                          const Divider(),
                          TextButton.icon(
                            onPressed: scanQRCore,
                            icon: const Icon(Icons.qr_code),
                            label: const Text('QR-Code scannen'),
                          ),
                          const Divider(),
                          TextButton(
                            onPressed: manualLogin,
                            child: const Text('Manueller Log-in'),
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    label: const Text('Zurück'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            ],
          )
        ),
      ),
    );
  }

  void searchSchool() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchSchoolScreen()),
    );
  }

  void scanQRCore() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanQrCodeScreen()),
    );
  }

  void manualLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManualLoginScreen()),
    );
  }
}
