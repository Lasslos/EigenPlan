import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/provider/specified_message_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';

class MessageDetailScreen extends ConsumerWidget {
  final int messageId;

  const MessageDetailScreen({required this.messageId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session =
    ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final message = ref.watch(messageDetailProvider(session, messageId));
    final canMakeRequest = ref.watch(canMakeRequestProvider);
    final requestState = canMakeRequest
        ? ref.watch(requestSpecifiedMessageProvider(session, messageId))
        : null;

    Widget body;
    if (message != null) {
      body = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.subject,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              message.sender.displayName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            Text(message.content),
          ],
        ),
      );
    } else if (!canMakeRequest) {
      body = const Center(child: Text('Keine gecachten Daten verfügbar'));
    } else if (requestState?.hasError == true) {
      body = const Center(child: Text('Fehler beim Laden der Nachricht'));
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nachricht')),
      body: body,
    );
  }
}
