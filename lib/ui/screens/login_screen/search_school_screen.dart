import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/rpc_request/rpc_error.dart';
import 'package:your_schedule/core/untis/models/school_search/school.dart';
import 'package:your_schedule/core/untis/requests/request_login_meta.dart';
import 'package:your_schedule/core/untis/requests/request_school_list.dart';
import 'package:your_schedule/ui/screens/login_screen/anonymous_login_screen.dart';
import 'package:your_schedule/ui/screens/login_screen/login_screen.dart';
import 'package:your_schedule/util/logger.dart';

class SearchSchoolScreen extends ConsumerStatefulWidget {
  const SearchSchoolScreen({super.key});

  @override
  ConsumerState createState() => _SearchSchoolScreenState();
}

class _SearchSchoolScreenState extends ConsumerState<SearchSchoolScreen> {
  String? message;
  bool messageIsError = false;
  List<School> schools = [];
  late FocusNode node;

  @override
  void initState() {
    super.initState();
    node = FocusNode();
    node.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    Future<List<ConnectivityResult>> connectivity = ref.watch(connectivityProvider.future);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 16),
              TextField(
                autocorrect: false,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.fullStreetAddress,
                ],
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  labelText: 'Schulname oder Adresse',
                  helperText: messageIsError ? null : message,
                  errorText: messageIsError ? message : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (s) => onTextChanged(s, connectivity),
                focusNode: node,
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (var school in schools)
                      ListTile(
                        title: Text(school.displayName),
                        subtitle: Text(school.address),
                        onTap: () => pickedSchool(school),
                      ),
                  ],
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
          ),
        ),
      ),
    );
  }


  Future<void> onTextChanged(String s, Future<List<ConnectivityResult>> connectivity) async {
    if (s.isEmpty) {
      setState(() {
        schools = [];
      });
      clearMessage();
      return;
    }

    if (s.length < 3) {
      setState(() {
        schools = [];
      });
      setMessage('Gib mindestens 3 Zeichen ein', false);
      return;
    }

    var connectivityResult = await connectivity;
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setMessage('Keine Internetverbindung', true);
      return;
    }

    try {
      var schools = await ref.read(requestSchoolListProvider(s).future);
      if (schools.isEmpty) {
        setState(() {
          this.schools = schools;
        });
        setMessage('Keine Ergebnisse', true);
      } else {
        setState(() {
          this.schools = schools;
        });
        clearMessage();
      }
    } on RPCError catch (e, s) {
      if (e.code == RPCError.tooManyResults) {
        setMessage('Zu viele Ergebnisse', false);
        return;
      }
      logRequestError('Error while requesting school list', e, s);
      setMessage(e.message, true);
    } on ClientException catch (e, s) {
      logRequestError('ClientException while requesting school list', e, s);
      setMessage(e.message, true);
    } catch (e, s) {
      logRequestError('Unknown error while requesting school list', e, s);
      setMessage(e.toString(), true);
    }
  }

  void setMessage(String message, bool isError) {
    setState(() {
      this.message = message;
      messageIsError = isError;
    });
  }
  void clearMessage() {
    setState(() {
      message = null;
      messageIsError = false;
    });
  }

  Future<void> pickedSchool(School school) async {
    // Anonymous schools skip the credential form entirely; everything else goes
    // through the regular login form, which tries password then falls back to
    // treating the entered value as a login key automatically — see
    // activateSessionInferringMode (not gated on login-meta: whether a given user
    // has a key is independent of whether the school broadly has SSO configured).
    var anonymousLoginEnabled = false;
    try {
      var loginMeta = await ref.read(requestLoginMetaProvider(school).future);
      anonymousLoginEnabled = loginMeta.anonymousLoginEnabled;
    } catch (e, s) {
      logRequestError('Error while requesting login-meta', e, s);
    }

    if (!mounted) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => anonymousLoginEnabled
            ? AnonymousLoginScreen(school: school)
            : LoginScreen(school: school),
      ),
    );
  }
}
