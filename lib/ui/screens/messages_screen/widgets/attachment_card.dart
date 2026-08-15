import 'package:flutter/material.dart';

/// A file attachment shown as a card: icon, filename, best-effort size, and a
/// download action. Works for both externally-hosted attachments (a plain link) and
/// Untis-storage-hosted ones (a signed URL the app has to fetch and open itself) —
/// [fetchSize] and [onDownload] encapsulate the difference, so this widget doesn't
/// need to know which kind it's rendering.
class AttachmentCard extends StatefulWidget {
  final String fileName;

  /// Best-effort file size in bytes, or `null` if it can't be determined (e.g. the
  /// host doesn't return `Content-Length`). Never throws — callers should catch
  /// their own errors and resolve to `null`.
  final Future<int?> Function() fetchSize;

  /// Performs the download (and, for a signed URL, opens the result) when the user
  /// taps the download button. Any error should be thrown normally; the card shows
  /// a snackbar on failure.
  final Future<void> Function() onDownload;

  const AttachmentCard({
    required this.fileName,
    required this.fetchSize,
    required this.onDownload,
    super.key,
  });

  @override
  State<AttachmentCard> createState() => _AttachmentCardState();
}

class _AttachmentCardState extends State<AttachmentCard> {
  late Future<int?> _sizeFuture;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _sizeFuture = widget.fetchSize();
  }

  IconData get _fileIcon {
    final extension = widget.fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'pdf' => Icons.picture_as_pdf,
      'doc' || 'docx' => Icons.description,
      'xls' || 'xlsx' => Icons.table_chart,
      'ppt' || 'pptx' => Icons.slideshow,
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => Icons.image,
      'zip' || 'rar' || '7z' => Icons.folder_zip,
      _ => Icons.insert_drive_file,
    };
  }

  Future<void> _handleDownload() async {
    setState(() {
      _downloading = true;
    });
    try {
      await widget.onDownload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anhang konnte nicht heruntergeladen werden')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var accentColor = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_fileIcon, color: accentColor),
        ),
        title: Text(widget.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: FutureBuilder<int?>(
          future: _sizeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Text('Lädt Größe…');
            }
            var bytes = snapshot.data;
            return Text(bytes != null ? _formatBytes(bytes) : 'Unbekannte Größe');
          },
        ),
        trailing: _downloading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.download),
                onPressed: _handleDownload,
              ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
