import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/rpc_request/rpc_error.dart';
import 'package:your_schedule/core/untis/models/login_meta/login_meta.dart';
import 'package:your_schedule/core/untis/models/school_search/school.dart';
import 'package:your_schedule/core/untis/requests/request_login_meta.dart';
import 'package:your_schedule/core/untis/requests/request_school_list.dart';
import 'package:your_schedule/core/untis/untis_session.dart';
import 'package:your_schedule/ui/screens/filter_screen/filter_screen.dart';
import 'package:your_schedule/ui/screens/home_screen/home_screen.dart';
import 'package:your_schedule/util/logger.dart';

class ManualLoginScreen extends ConsumerStatefulWidget {
  const ManualLoginScreen({super.key});

  @override
  ConsumerState<ManualLoginScreen> createState() => _ManualLoginScreenState();
}

class _ManualLoginScreenState extends ConsumerState<ManualLoginScreen> {
  late TextEditingController _urlFieldController;
  late TextEditingController _schoolFieldController;
  late TextEditingController _usernameFieldController;
  late TextEditingController _passwordFieldController;
  late TextEditingController _tokenFieldController;
  var isLoading = false;
  var showPassword = false;
  var requireTwoFactor = false;
  List<FocusNode> focusNodes = [];

  String message = '';

  @override
  void initState() {
    super.initState();
    _urlFieldController = TextEditingController();
    _schoolFieldController = TextEditingController();
    _usernameFieldController = TextEditingController();
    _passwordFieldController = TextEditingController();
    _tokenFieldController = TextEditingController();
    for (var i = 0; i < 6; i++) {
      focusNodes.add(FocusNode());
    }
    focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: buildLoginCard(context),
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
              ),
            );
          },
        ),
      ),
    );
  }


  Widget buildLoginCard(BuildContext context) {
    Future<List<ConnectivityResult>> connectivity = ref.watch(connectivityProvider.future);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Login',
                style: Theme
                    .of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Melde dich mit deinem Untis-Konto an',
                style: Theme
                    .of(context)
                    .textTheme
                    .labelMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                focusNode: focusNodes[0],
                autocorrect: false,
                autofillHints: const [AutofillHints.url],
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                controller: _urlFieldController,
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(focusNodes[1]);
                },
                decoration: const InputDecoration(
                  labelText: 'Untis-URL',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                focusNode: focusNodes[1],
                autocorrect: false,
                autofillHints: const [AutofillHints.organizationName],
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                controller: _schoolFieldController,
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(focusNodes[2]);
                },
                decoration: const InputDecoration(
                  labelText: 'Schule',
                  prefixIcon: Icon(Icons.school),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                focusNode: focusNodes[2],
                autocorrect: false,
                autofillHints: const [AutofillHints.username],
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                controller: _usernameFieldController,
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(focusNodes[3]);
                },
                decoration: const InputDecoration(
                  labelText: 'Benutzername',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                focusNode: focusNodes[3],
                autocorrect: false,
                enableSuggestions: false,
                obscureText: !showPassword,
                keyboardType: TextInputType.visiblePassword,
                autofillHints: const [AutofillHints.password],
                textInputAction: requireTwoFactor
                    ? TextInputAction.next
                    : TextInputAction.done,
                controller: _passwordFieldController,
                onEditingComplete: () {
                  if (requireTwoFactor) {
                    FocusScope.of(context).requestFocus(focusNodes[4]);
                  } else {
                    FocusScope.of(context).unfocus();
                    _login(connectivity);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: showPassword
                        ? const Icon(Icons.visibility)
                        : const Icon(Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedCrossFade(
                crossFadeState: requireTwoFactor
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 150),
                firstChild: const SizedBox(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    focusNode: focusNodes[4],
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    textInputAction: TextInputAction.done,
                    controller: _tokenFieldController,
                    onEditingComplete: () {
                      FocusScope.of(context).unfocus();
                      _login(connectivity);
                    },
                    decoration: const InputDecoration(
                      labelText: '2FA-Token',
                      prefixIcon: Icon(Icons.security_outlined),
                    ),
                  ),
                ),
              ),
              Text(
                message,
                style: Theme
                    .of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isLoading
                    ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: LinearProgressIndicator(),
                    ),
                  ),
                )
                    : ElevatedButton(
                  focusNode: focusNodes[5],
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Theme
                          .of(context)
                          .colorScheme
                          .primary,
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      Theme
                          .of(context)
                          .colorScheme
                          .onPrimary,
                    ),
                    textStyle: WidgetStateProperty.all(
                      Theme
                          .of(context)
                          .textTheme
                          .labelLarge,
                    ),
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _login(connectivity);
                  },
                  child: const Text('Log In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login(Future<List<ConnectivityResult>> connectivity) async {
    setState(() {
      isLoading = true;
    });

    var connectivityResult = await connectivity;
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        message = 'Keine Internetverbindung';
        isLoading = false;
      });
      return;
    }

    List<School> schools;
    try {
      schools = await ref.read(
          requestSchoolListProvider(_schoolFieldController.text).future);
    } on RPCError catch (e) {
      setState(() {
        message = 'Fehler: ${e.message}';
        isLoading = false;
      });
      return;
    } catch (e, s) {
      getLogger().e('Error while requesting school list', error: e, stackTrace: s);
      setState(() {
        message = 'Fehler: ${e.toString()}';
        isLoading = false;
      });
      return;
    }

    School school = schools.firstWhereOrNull(
        (school) {
          if (school.server == _urlFieldController.text.trim()
            && school.loginName == _schoolFieldController.text.trim()) {
            getLogger().i('Found matching school');
            return true;
          }
          return false;
        }
    ) ?? (School(
      _urlFieldController.text.trim(),
      'No address',
      _schoolFieldController.text.trim(),
      _schoolFieldController.text.trim(),
      -1,
      'https://${_urlFieldController.text.trim()}/WebUntis/?school=${_schoolFieldController.text.trim()}',
    ).also((_) => getLogger().w('Did not find matching school')));

    LoginMeta loginMeta;
    try {
      loginMeta = await ref.read(requestLoginMetaProvider(school).future);
    } catch (e, s) {
      logRequestError('Error while requesting login-meta', e, s);
      setState(() {
        message = 'Fehler: ${e.toString()}';
        isLoading = false;
      });
      return;
    }

    try {
      var session = await activateSessionInferringMode(
        ref,
        school,
        loginMeta,
        _usernameFieldController.text,
        _passwordFieldController.text,
        token: _tokenFieldController.text,
      );
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
          requireTwoFactor = true;
        });
        focusNodes[2].requestFocus();
        return;
      }

      setState(() {
        message = switch (e.code) {
          RPCError.authenticationFailed => 'Falsche Anmeldedaten',
          RPCError.invalidTwoFactor => 'Falscher 2-Faktor-Token',
          RPCError.invalidSchoolName => 'Ungültiger Schulname',
          int() => e.message,
        };
      });
    } on ClientException catch (e, s) {
      getLogger().e('ClientException while logging in', error: e, stackTrace: s);
      setState(() {
        message = e.toString();
      });
    } catch (e, s) {
      getLogger().e('Unknown Error while logging in', error: e, stackTrace: s);
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
