import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:vibration/vibration.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/rpc_request/rpc_error.dart';
import 'package:your_schedule/core/untis/models/school_search/school.dart';
import 'package:your_schedule/core/untis/requests/request_school_list.dart';
import 'package:your_schedule/core/untis/untis_session.dart';
import 'package:your_schedule/ui/screens/filter_screen/filter_screen.dart';
import 'package:your_schedule/ui/screens/home_screen/home_screen.dart';
import 'package:your_schedule/ui/screens/login_screen/widgets/qr_code_scanner.dart';
import 'package:your_schedule/util/logger.dart';

class ScanQrCodeScreen extends ConsumerStatefulWidget {
  const ScanQrCodeScreen({super.key});

  @override
  ConsumerState createState() => _ScanQrCodeScreenState();
}

class _ScanQrCodeScreenState extends ConsumerState<ScanQrCodeScreen> {
  String? message;

  @override
  Widget build(BuildContext context) {
    Future<List<ConnectivityResult>> connectivity = ref.watch(connectivityProvider.future);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'QR-Code scannen',
                        style: Theme.of(context).textTheme
                            .headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: QRCodeScanner(
                          onScan: (barcode) => onScan(connectivity, barcode),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: lock ? 1 : 0,
                        child: const LinearProgressIndicator(),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        message ?? "",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
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
                    label: const Text("Zurück"),
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

  bool lock = false;

  Future<void> onScan(Future<List<ConnectivityResult>> connectivity, String barcode) async {
    if (lock) {
      return;
    }
    setState(() {
      lock = true;
    });

    if (await Vibration.hasVibrator()) {
      getLogger().i("Vibrating");
      await Vibration.vibrate(amplitude: 64, duration: 32);
    }

    await _login(connectivity, barcode);

    if (mounted) {
      setState(() {
        lock = false;
      });
    }
  }

  Future<void> _login(Future<List<ConnectivityResult>> connectivity, String barcode) async {
    var connectivityResult = await connectivity;
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        message = "Keine Internetverbindung";
      });
      return;
    }

    if (barcode.isEmpty) {
      getLogger().w("QR-Code is empty");
      setState(() {
        message = "QR-Code ist leer";
      });
      return;
    }

    if (!barcode.startsWith("untis://setschool?")) {
      getLogger().w("QR-Code is not a valid Untis QR-Code");
      setState(() {
        message = "QR-Code ist kein gültiger Untis-QR-Code";
      });
      return;
    }

    Map<String, String> parameters = {};
    for (String parameter in barcode.split("?")[1].split("&")) {
      List<String> parameterSplit = parameter.split("=");
      parameters[parameterSplit[0]] = parameterSplit[1];
    }

    String url = parameters["url"]!;
    String schoolString = parameters["school"]!;
    String user = parameters["user"]!;
    String key = parameters["key"]!;
    int schoolNumber = int.parse(parameters["schoolNumber"]!);

    List<School> schools = await ref.read(requestSchoolListProvider(schoolString).future);
    School school = schools.firstWhereOrNull((school) {
          if (school.server == url && school.loginName == schoolString && school.schoolId == schoolNumber) {
            getLogger().i("Found matching school");
            return true;
          }
          return false;
        }
    ) ?? (School(
      url,
      "No address",
      schoolString,
      schoolString,
      -1,
      "https://$url/WebUntis/?school=$schoolString",
    ).also((_) => getLogger().w("Did not find matching school")));

    UntisSession session = UntisSession.inactive(
      school: school,
      username: user,
      password: key,
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
      if (e.code == RPCError.twoFactorRequired) {
        setState(() {
          message = "2-Faktor-Authentifizierung benötigt, bitte benutze den manuellen Log-In";
        });
        return;
      }

      setState(() {
        message = switch (e.code) {
          RPCError.authenticationFailed => "Falsches Passwort",
          RPCError.invalidTwoFactor => "Falscher 2-Faktor-Token",
          RPCError.invalidSchoolName => "Ungültiger Schulname",
          RPCError.userLocked => "Benutzer gesperrt",
          int() => e.message,
        };
      });
    } on ClientException catch (e, s) {
      getLogger().e("ClientException while logging in", error: e, stackTrace: s);
      setState(() {
        message = e.toString();
      });
    } catch (e, s) {
      getLogger().e("Unknown error while logging in", error: e, stackTrace: s);
      setState(() {
        message = e.toString();
      });
    }
  }
}
