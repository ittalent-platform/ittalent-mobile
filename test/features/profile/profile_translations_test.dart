import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> keys(Map<String, Object?> map, [String prefix = '']) {
  final result = <String>{};
  for (final entry in map.entries) {
    final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    result.add(path);
    if (entry.value case final Map<Object?, Object?> value) {
      result.addAll(keys(Map<String, Object?>.from(value), path));
    }
  }
  return result;
}

Map<String, Object?> readTranslations(String path) {
  final value = jsonDecode(File(path).readAsStringSync());
  if (value is! Map<String, Object?>) {
    throw const FormatException('Translation file must contain an object');
  }
  return value;
}

void main() {
  test('English and Vietnamese Profile translation keys remain 1:1', () {
    final en = readTranslations('assets/translations/en.json');
    final vi = readTranslations('assets/translations/vi.json');
    final enProfile = Map<String, Object?>.from(
      en['profile']! as Map<Object?, Object?>,
    );
    final viProfile = Map<String, Object?>.from(
      vi['profile']! as Map<Object?, Object?>,
    );
    expect(keys(enProfile).difference(keys(viProfile)), isEmpty);
    expect(keys(viProfile).difference(keys(enProfile)), isEmpty);
  });
}
