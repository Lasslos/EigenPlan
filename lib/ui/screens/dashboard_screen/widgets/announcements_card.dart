import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/dashboard_screen/widgets/dashboard_summary_card.dart';
import 'package:your_schedule/util/date.dart';

const _maxItemsShown = 3;

/// School-posted dashboard announcements — renders nothing at all (not even an empty
/// state) while loading, on error, or when there are no cards, since most schools
/// never post any. Uses the same [DashboardSummaryCard] shell as the other cards, so
/// it reads as an equal part of the dashboard rather than a smaller afterthought.
class AnnouncementsCard extends ConsumerWidget {
  const AnnouncementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final cards = ref.watch(requestDashboardCardsProvider(session));

    return cards.maybeWhen(
      data: (cards) {
        if (cards.isEmpty) {
          return const SizedBox.shrink();
        }
        final sorted = [...cards]..sort((a, b) => (a.orderNo ?? 0).compareTo(b.orderNo ?? 0));
        final displayed = sorted.take(_maxItemsShown).toList();

        // Only worth the extra request if something here actually claims an
        // attachment — `/dashboard/cards` doesn't carry the real link, so
        // `getMessagesOfDay2017` (keyed by the same id) is fetched to resolve it.
        final attachmentsById = displayed.any((c) => c.hasAttachments)
            ? ref.watch(requestMessagesOfDayProvider(session, Date.now())).maybeWhen(
                  data: (messages) => {for (final m in messages) m.id: m.attachments},
                  orElse: () => const <int, List<MessageOfDayAttachment>>{},
                )
            : const <int, List<MessageOfDayAttachment>>{};

        return DashboardSummaryCard(
          title: 'Ankündigungen',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final card in displayed)
                _AnnouncementTile(card: card, attachments: attachmentsById[card.id] ?? const []),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

IconData _iconFor(String? icon) => switch (icon) {
      'megaphone' => Icons.campaign_outlined,
      _ => Icons.info_outline,
    };

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.card, required this.attachments});

  final DashboardCard card;
  final List<MessageOfDayAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(_iconFor(card.icon), size: 20),
            title: Text(card.title),
            subtitle: card.subtitle != null ? Text(card.subtitle!) : null,
          ),
          for (final attachment in attachments) _AttachmentLink(attachment: attachment),
        ],
      ),
    );
  }
}

class _AttachmentLink extends StatelessWidget {
  const _AttachmentLink({required this.attachment});

  final MessageOfDayAttachment attachment;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(attachment.url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Could not launch $uri');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anhang konnte nicht geöffnet werden')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 32),
      minLeadingWidth: 0,
      leading: const Icon(Icons.attach_file, size: 16),
      title: Text(attachment.name, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () => _open(context),
    );
  }
}
