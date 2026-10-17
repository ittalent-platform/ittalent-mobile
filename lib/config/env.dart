import 'package:flutter/foundation.dart';

class AppEnv {
  const AppEnv._();

  static const String appName = 'IT-Talent';

  // Default to localhost:3001, or 10.0.2.2:3001 for Android emulator
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) {
      return 'http://localhost:3001';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001';
    } else {
      return 'http://localhost:3001';
    }
  }
}
