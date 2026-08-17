import 'package:flutter/material.dart';

/// A file attachment shown as a card: icon, filename, and a download action. Works
/// for both externally-hosted attachments (a plain link) and Untis-storage-hosted
/// ones (a signed URL the app has to fetch and open itself) — [onDownload]
/// encapsulates the difference, so this widget doesn't need to know which kind it's
/// rendering.
class AttachmentCard extends StatefulWidget {
  final String fileName;

  /// Performs the download (and, for a signed URL, opens the result) when the user
  /// taps the card. Any error should be thrown normally; the card shows a snackbar
  /// on failure.
  final Future<void> Function() onDownload;

  const AttachmentCard({
    required this.fileName,
    required this.onDownload,
    super.key,
  });

  @override
  State<AttachmentCard> createState() => _AttachmentCardState();
}

class _AttachmentCardState extends State<AttachmentCard> {
  bool _downloading = false;

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
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: _downloading ? null : _handleDownload,
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
        trailing: _downloading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Icon(Icons.download, color: accentColor),
      ),
    );
  }
}
