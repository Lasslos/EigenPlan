import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_attachment_storage_url.g.dart';

/// Resolves a [StorageAttachment.id] into a short-lived, pre-signed download URL —
/// pass the result to [downloadAttachment] to actually fetch the file. No caching:
/// the URL expires in minutes, so there's nothing worth persisting.
@riverpod
Future<AttachmentStorageUrl> requestAttachmentStorageUrl(
  Ref ref,
  UntisSession activeSession,
  String attachmentId,
) async {
  assert(activeSession is ActiveUntisSession, 'Session must be active!');
  ActiveUntisSession session = activeSession as ActiveUntisSession;

  final uri = Uri.https(
    session.school.server,
    '/WebUntis/api/rest/view/v1/messages/$attachmentId/attachmentstorageurl',
    {'school': session.school.loginName},
  );

  AuthToken authToken = await ref.read(authTokenProvider(session).future);

  http.Response response;
  try {
    response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${authToken.jwt}'},
    );
  } catch (e, s) {
    getLogger().e('Error while requesting attachment storage url', error: e, stackTrace: s);
    rethrow;
  }

  switch (response.statusCode) {
    case 200:
      return AttachmentStorageUrl.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    default:
      getLogger().e('HTTP Error: ${response.statusCode} ${response.reasonPhrase}');
      throw HttpException(
        response.statusCode,
        response.reasonPhrase.toString(),
        uri: uri,
      );
  }
}

/// Fetches the actual attachment bytes for a resolved [storageUrl] — the
/// [AttachmentStorageUrl.additionalHeaders] (SSE-C decryption headers) must be
/// replayed verbatim, or the request fails. What to do with the bytes (save, share,
/// preview) is left to the caller — no file-system/download UI exists in this app
/// yet, see `docs/api/spec/NOTES.md` §7.
Future<Uint8List> downloadAttachment(AttachmentStorageUrl storageUrl) async {
  http.Response response;
  try {
    response = await http.get(
      Uri.parse(storageUrl.downloadUrl),
      headers: {
        for (var header in storageUrl.additionalHeaders) header.key: header.value,
      },
    );
  } catch (e, s) {
    getLogger().e('Error while downloading attachment', error: e, stackTrace: s);
    rethrow;
  }

  if (response.statusCode != 200) {
    getLogger().e('HTTP Error: ${response.statusCode} ${response.reasonPhrase}');
    throw HttpException(
      response.statusCode,
      response.reasonPhrase.toString(),
      uri: Uri.parse(storageUrl.downloadUrl),
    );
  }

  return response.bodyBytes;
}
