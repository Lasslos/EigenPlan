import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Nachricht')),
      body: message == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
      ),
    );
  }
}
