import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:your_schedule/core/provider/specified_message_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/messages_screen/widgets/attachment_card.dart';

class MessageDetailScreen extends ConsumerWidget {
  final int messageId;

  const MessageDetailScreen({required this.messageId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session =
    ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final message = ref.watch(messageDetailProvider(session, messageId));
    final replyHistory = message == null
        ? const <ReplyHistoryEntry>[]
        : (List.of(message.replyHistory)
          ..sort((a, b) => a.sentDateTime.compareTo(b.sentDateTime)));

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
            const Divider(height: 24),
            // Earlier messages in the thread (e.g. the outgoing message this one
            // replies to) come first, oldest to newest, so the thread reads
            // chronologically ending with the current message below. The API's
            // own replyHistory order isn't reliably chronological, so sort it
            // explicitly rather than trusting it.
            for (var entry in replyHistory)
              _ThreadEntry(
                session: session,
                sender: entry.sender.displayName,
                sentDateTime: entry.sentDateTime,
                content: entry.content,
                attachments: entry.attachments,
                storageAttachments: entry.storageAttachments,
              ),
            _ThreadEntry(
              session: session,
              sender: message.sender.displayName,
              sentDateTime: message.sentDateTime,
              content: message.content,
              attachments: message.attachments,
              storageAttachments: message.storageAttachments,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadEntry extends StatelessWidget {
  const _ThreadEntry({
    required this.session,
    required this.sender,
    required this.sentDateTime,
    required this.content,
    required this.attachments,
    required this.storageAttachments,
  });

  final ActiveUntisSession session;
  final String sender;
  final DateTime sentDateTime;
  final String? content;
  final List<ExternalAttachment> attachments;
  final List<StorageAttachment> storageAttachments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sender, style: theme.textTheme.titleSmall),
              Text(
                '${sentDateTime.day}.${sentDateTime.month.toString().padLeft(2, '0')}.${sentDateTime.year} '
                '${sentDateTime.hour.toString().padLeft(2, '0')}:${sentDateTime.minute.toString().padLeft(2, '0')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (var attachment in attachments)
            AttachmentCard(
              fileName: attachment.name,
              onDownload: () => _openExternal(attachment),
            ),
          for (var attachment in storageAttachments)
            _StorageAttachmentCard(session: session, attachment: attachment),
          if (attachments.isNotEmpty || storageAttachments.isNotEmpty)
            const SizedBox(height: 8),
          Text(content ?? ''),
        ],
      ),
    );
  }
}

Future<void> _openExternal(ExternalAttachment attachment) async {
  var uri = Uri.parse(attachment.downloadUrl);
  var launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    throw Exception('Could not launch $uri');
  }
}

/// A signed storage URL requires the SSE-C headers to be replayed, so a plain
/// "open this link" (as for [ExternalAttachment]) doesn't work — the app has to
/// fetch the bytes itself, then hand the OS a local file to open with whatever app
/// it has for that file type. Resolving the signed URL is its own request
/// (`attachmentstorageurl`), so this widget caches that resolution for its own
/// lifetime.
class _StorageAttachmentCard extends ConsumerStatefulWidget {
  final ActiveUntisSession session;
  final StorageAttachment attachment;

  const _StorageAttachmentCard({required this.session, required this.attachment});

  @override
  ConsumerState<_StorageAttachmentCard> createState() => _StorageAttachmentCardState();
}

class _StorageAttachmentCardState extends ConsumerState<_StorageAttachmentCard> {
  Future<AttachmentStorageUrl>? _resolved;

  Future<AttachmentStorageUrl> _resolve() {
    _resolved ??= ref.read(requestAttachmentStorageUrlProvider(widget.session, widget.attachment.id).future);
    return _resolved!;
  }

  Future<void> _downloadAndOpen() async {
    var resolved = await _resolve();
    var bytes = await downloadAttachment(resolved);

    var directory = await getTemporaryDirectory();
    var file = File('${directory.path}/${widget.attachment.name}');
    await file.writeAsBytes(bytes);

    var result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception('Could not open ${file.path}: ${result.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AttachmentCard(
      fileName: widget.attachment.name,
      onDownload: _downloadAndOpen,
    );
  }
}
