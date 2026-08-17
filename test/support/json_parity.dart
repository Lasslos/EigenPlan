import 'dart:convert';

/// Recursively diffs [raw] (decoded API JSON) against [model] by round-tripping
/// [model] through `jsonEncode`/`jsonDecode`, and returns dotted-path keys present in
/// [raw] but absent from that round-trip — i.e. fields the model silently drops.
///
/// Routing [model] through `jsonEncode` (rather than calling `.toJson()` and diffing
/// directly) normalizes nested Freezed objects to plain `Map`/`List` regardless of
/// whether a given model's `toJson` uses `explicitToJson`, so this works uniformly
/// across the model set. An empty result means every key the server sent is
/// represented somewhere in the model; a non-empty result flags API surface this
/// codebase doesn't parse yet — intentional gaps should be recorded as an explicit
/// allow-list at the call site (see model test files) so *new* gaps still fail loudly.
List<String> findUnparsedKeys(dynamic raw, Object? model) {
  final reencoded = jsonDecode(jsonEncode(model));
  return _diff(raw, reencoded, '');
}

/// Collapses list indices in a [findUnparsedKeys] path (`klassen[42].foreColor` →
/// `klassen[].foreColor`) so a known-gap allow-list stays a fixed size regardless of
/// how many items a real API response happens to contain — needed for live data
/// (unlike small hand-written fixtures, a real school's `klassen`/`rooms`/`subjects`
/// list length varies per account).
String normalizeKeyPath(String path) => path.replaceAll(RegExp(r'\[\d+\]'), '[]');

List<String> _diff(dynamic raw, dynamic reencoded, String path) {
  final missing = <String>[];
  if (raw is Map) {
    final re = reencoded is Map ? reencoded : const {};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final childPath = path.isEmpty ? key : '$path.$key';
      if (!re.containsKey(key)) {
        missing.add(childPath);
      } else {
        missing.addAll(_diff(entry.value, re[key], childPath));
      }
    }
  } else if (raw is List) {
    final re = reencoded is List ? reencoded : const [];
    for (var i = 0; i < raw.length; i++) {
      missing.addAll(_diff(raw[i], i < re.length ? re[i] : null, '$path[$i]'));
    }
  }
  return missing;
}
