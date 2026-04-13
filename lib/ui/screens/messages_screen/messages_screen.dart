import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/messages_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/messages_screen/message_detail_screen.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session =
    ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final messages = ref.watch(inboxMessagesProvider(session));

    return Scaffold(
      appBar: AppBar(title: const Text('Nachrichten')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(requestMessagesProvider(session));
          await ref.read(requestMessagesProvider(session).future);
        },
        child: ListView.builder(
          itemCount: messages.incomingMessages.length,
          itemBuilder: (context, index) {
            final msg = messages.incomingMessages[index];
            return ListTile(
              leading: Icon(
                msg.isMessageRead ? Icons.mail_outline : Icons.mail,
              ),
              title: Text(msg.subject),
              subtitle: Text(
                msg.contentPreview,
                maxLines: 1,                          // Feature 1
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(msg.sender.displayName),
              onTap: () {                             // Feature 2
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MessageDetailScreen(messageId: msg.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
