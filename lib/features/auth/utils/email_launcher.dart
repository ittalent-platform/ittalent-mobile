import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper to open the device's native mail app or fallback to webmail/inbox.
Future<bool> launchEmailApp(
  BuildContext context, {
  String? email,
  @visibleForTesting
  Future<bool> Function(Uri uri, {LaunchMode mode})? urlLauncher,
  @visibleForTesting Future<bool> Function(Uri uri)? canLaunchUrlChecker,
}) async {
  final mailtoUri = Uri(scheme: 'mailto');
  final launcher =
      urlLauncher ??
      (uri, {mode = LaunchMode.platformDefault}) => launchUrl(uri, mode: mode);
  final canLaunch = canLaunchUrlChecker ?? canLaunchUrl;

  try {
    if (await canLaunch(mailtoUri)) {
      final launched = await launcher(
        mailtoUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    }
  } catch (_) {
    // If mailto throws or cannot be handled by the platform, fall through to webmail fallback
  }

  // Fallback to webmail inbox if domain is known
  if (email != null && email.contains('@')) {
    final domain = email.split('@').last.toLowerCase().trim();
    Uri? webMailUri;
    if (domain == 'gmail.com' || domain.contains('google')) {
      webMailUri = Uri.parse('https://mail.google.com');
    } else if (domain == 'outlook.com' ||
        domain == 'hotmail.com' ||
        domain == 'live.com' ||
        domain.contains('microsoft')) {
      webMailUri = Uri.parse('https://outlook.live.com');
    } else if (domain == 'yahoo.com') {
      webMailUri = Uri.parse('https://mail.yahoo.com');
    }

    if (webMailUri != null) {
      try {
        if (await canLaunch(webMailUri)) {
          final launched = await launcher(
            webMailUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } catch (_) {}
    }
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not open email app. Please check your inbox manually.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  return false;
}
