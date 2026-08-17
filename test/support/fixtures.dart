import 'dart:convert';
import 'dart:io';

/// Raw (undecoded) contents of `test/fixtures/[name]`. Paths are resolved relative to
/// the repo root, which is `flutter test`'s working directory.
String loadFixtureRaw(String name) {
  return File('test/fixtures/$name').readAsStringSync();
}

/// Loads and decodes a JSON fixture from `test/fixtures/[name]`. Paths are resolved
/// relative to the repo root, which is `flutter test`'s working directory.
dynamic loadFixture(String name) {
  return jsonDecode(loadFixtureRaw(name));
}

/// [loadFixture], typed as a `Map` — the common case for a single JSON object.
Map<String, dynamic> loadFixtureMap(String name) {
  return loadFixture(name) as Map<String, dynamic>;
}
