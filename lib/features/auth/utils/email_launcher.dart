import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/common/app_toast.dart';

const MethodChannel _emailChannel = MethodChannel(
  'com.example.ittalent_mobile/email_launcher',
);

/// Helper to open the device's native mail inbox or fallback to webmail.
Future<bool> launchEmailApp(
  BuildContext context, {
  String? email,
  @visibleForTesting Future<bool> Function(String? email)? nativeLauncher,
  @visibleForTesting
  Future<bool> Function(Uri uri, {LaunchMode mode})? urlLauncher,
  @visibleForTesting Future<bool> Function(Uri uri)? canLaunchUrlChecker,
}) async {
  // 1. Try native platform inbox launch on Android first
  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  if (nativeLauncher != null) {
    try {
      final launched = await nativeLauncher(email);
      if (launched) return true;
    } catch (_) {}
  } else if (isAndroid) {
    try {
      final launched = await _emailChannel.invokeMethod<bool>('openEmailApp', {
        'email': email,
      });
      if (launched == true) return true;
    } catch (_) {}
  }

  // 2. iOS schemes & Webmail fallbacks
  final launcher =
      urlLauncher ??
      (uri, {mode = LaunchMode.platformDefault}) => launchUrl(uri, mode: mode);
  final canLaunch = canLaunchUrlChecker ?? canLaunchUrl;

  final domain = (email != null && email.contains('@'))
      ? email.split('@').last.toLowerCase().trim()
      : null;

  final candidates = <Uri>[];

  if (domain != null) {
    if (domain == 'gmail.com' || domain.contains('google')) {
      candidates.add(Uri.parse('googlegmail://'));
      candidates.add(Uri.parse('https://mail.google.com'));
    } else if (domain == 'outlook.com' ||
        domain == 'hotmail.com' ||
        domain == 'live.com' ||
        domain.contains('microsoft')) {
      candidates.add(Uri.parse('ms-outlook://'));
      candidates.add(Uri.parse('https://outlook.live.com'));
    } else if (domain == 'yahoo.com') {
      candidates.add(Uri.parse('ymail://'));
      candidates.add(Uri.parse('https://mail.yahoo.com'));
    }
  }

  // Generic fallback: iOS Apple Mail, and fallback webmail
  candidates.addAll([
    Uri.parse('message://'),
    Uri.parse('https://mail.google.com'),
  ]);

  for (final uri in candidates) {
    try {
      if (await canLaunch(uri)) {
        final launched = await launcher(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }
    } catch (_) {
      // If platform fails to launch this candidate, try the next one
    }
  }

  if (context.mounted) {
    showAppToast(
      ScaffoldMessenger.of(context),
      'Could not open email app. Please check your inbox manually.',
      error: true,
    );
  }
  return false;
}
