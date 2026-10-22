import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';

/// Loads the locale files and rewrites `{{name}}` placeholders to `{name}`.
///
/// The files are shared with the web (i18next style, `{{name}}`), but
/// easy_localization only replaces `{name}` and would leave the outer braces
/// in the text ("Submitted {20 Oct}"). Converting once at load keeps every
/// `tr(key, namedArgs: ...)` call site as it is.
class DoubleBraceAssetLoader extends AssetLoader {
  const DoubleBraceAssetLoader({this.delegate = const RootBundleAssetLoader()});

  final AssetLoader delegate;

  static final RegExp _placeholder = RegExp(r'\{\{\s*(\w+)\s*\}\}');

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final data = await delegate.load(path, locale);
    return data == null ? null : convert(data);
  }

  static Map<String, dynamic> convert(Map<String, dynamic> source) =>
      source.map((key, value) => MapEntry(key, _convertValue(value)));

  static Object? _convertValue(Object? value) {
    if (value is String) {
      return value.replaceAllMapped(_placeholder, (m) => '{${m[1]}}');
    }
    if (value is Map<String, dynamic>) return convert(value);
    return value;
  }
}
