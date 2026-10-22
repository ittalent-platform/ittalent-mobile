import 'dart:io';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/utils/double_brace_asset_loader.dart';

class _FakeLoader extends AssetLoader {
  const _FakeLoader(this.data);

  final Map<String, dynamic>? data;

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async => data;
}

void main() {
  test('rewrites {{name}} to {name}, also in nested maps and with spaces', () {
    final converted = DoubleBraceAssetLoader.convert({
      'submitted': 'Submitted {{date}}',
      'nested': {
        'both': '{{ done }} done, {{failed}} left',
        'count_one': '<b>{{count}} certificate</b>',
      },
      'plain': 'No placeholders',
      'number': 3,
    });
    expect(converted['submitted'], 'Submitted {date}');
    expect((converted['nested'] as Map)['both'], '{done} done, {failed} left');
    expect(
      (converted['nested'] as Map)['count_one'],
      '<b>{count} certificate</b>',
    );
    expect(converted['plain'], 'No placeholders');
    expect(converted['number'], 3);
  });

  test('converts what the delegate loads and passes null through', () async {
    expect(
      await const DoubleBraceAssetLoader(
        delegate: _FakeLoader({'k': 'Hi {{name}}'}),
      ).load('p', const Locale('en')),
      {'k': 'Hi {name}'},
    );
    expect(
      await const DoubleBraceAssetLoader(delegate: _FakeLoader(null))
          .load('p', const Locale('en')),
      isNull,
    );
  });

  test('the real locale files end up with no double braces left', () {
    // Guards the loader's regex against placeholder shapes it does not know.
    final remaining = RegExp(r'\{\{');
    for (final lang in ['en', 'vi']) {
      final text = File('assets/translations/$lang.json').readAsStringSync();
      final converted = DoubleBraceAssetLoader.convert({'all': text});
      expect(
        remaining.hasMatch(converted['all'] as String),
        isFalse,
        reason: '$lang.json has a {{...}} the loader cannot rewrite',
      );
    }
  });
}
