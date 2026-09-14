import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/clock_provider.dart';
import 'package:your_schedule/core/provider/messages_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/dashboard_screen/widgets/dashboard_summary_card.dart';
import 'package:your_schedule/ui/screens/messages_screen/message_detail_screen.dart';
import 'package:your_schedule/ui/screens/messages_screen/messages_screen.dart';
import 'package:your_schedule/util/date.dart';

const _windowDays = 7;
const _maxItemsShown = 4;

/// Messages from today and the [_windowDays] - 1 preceding calendar days, capped to
/// [_maxItemsShown] —
/// "Alle anzeigen" is the only remaining path to [MessagesScreen], so it's always
/// shown, even when this card's own filtered list is empty. Only ever built for a
/// non-anonymous session — [DashboardScreen] guards that, same as the old drawer did.
class MessagesSummaryCard extends ConsumerWidget {
  const MessagesSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final messages = ref.watch(inboxMessagesProvider(session));

    final today = ref.watch(todayProvider);
    final cutoff = today.subtractDays(_windowDays - 1);
    final items = messages.incomingMessages.where((m) => !Date(m.sentDateTime).isBefore(cutoff)).toList()
      ..sort((a, b) => b.sentDateTime.compareTo(a.sentDateTime));

    final displayed = items.take(_maxItemsShown).toList();
    final remaining = items.length - displayed.length;

    return DashboardSummaryCard(
      title: 'Nachrichten',
      onShowMore: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MessagesScreen()),
      ),
      child: items.isEmpty
          ? const Text('Keine Nachrichten in den letzten 7 Tagen.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final msg in displayed) _MessageSummaryTile(msg: msg, today: today),
                if (remaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('+$remaining weitere', style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
            ),
    );
  }
}

class _MessageSummaryTile extends StatelessWidget {
  const _MessageSummaryTile({required this.msg, required this.today});

  final IncomingMessage msg;
  final Date today;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        msg.isMessageRead ? Icons.mail_outline : Icons.mark_email_unread,
        size: 20,
      ),
      title: Text(
        msg.subject,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: msg.isMessageRead ? FontWeight.normal : FontWeight.bold),
      ),
      subtitle: Text(msg.sender.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        formatMessageTimestamp(msg.sentDateTime, today),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MessageDetailScreen(messageId: msg.id)),
      ),
    );
  }
}
