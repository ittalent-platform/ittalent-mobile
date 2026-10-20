import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper to open the device's native mail inbox or fallback to webmail.
Future<bool> launchEmailApp(
  BuildContext context, {
  String? email,
  @visibleForTesting
  Future<bool> Function(Uri uri, {LaunchMode mode})? urlLauncher,
  @visibleForTesting Future<bool> Function(Uri uri)? canLaunchUrlChecker,
}) async {
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
      // Direct Gmail app launcher, then iOS scheme, then webmail inbox
      candidates.add(
        Uri.parse(
          'intent:#Intent;action=android.intent.action.MAIN;package=com.google.android.gm;end',
        ),
      );
      candidates.add(Uri.parse('googlegmail://'));
      candidates.add(Uri.parse('https://mail.google.com'));
    } else if (domain == 'outlook.com' ||
        domain == 'hotmail.com' ||
        domain == 'live.com' ||
        domain.contains('microsoft')) {
      // Direct Outlook app launcher, then iOS scheme, then webmail inbox
      candidates.add(
        Uri.parse(
          'intent:#Intent;action=android.intent.action.MAIN;package=com.microsoft.office.outlook;end',
        ),
      );
      candidates.add(Uri.parse('ms-outlook://'));
      candidates.add(Uri.parse('https://outlook.live.com'));
    } else if (domain == 'yahoo.com') {
      // Direct Yahoo app launcher, then iOS scheme, then webmail inbox
      candidates.add(
        Uri.parse(
          'intent:#Intent;action=android.intent.action.MAIN;package=com.yahoo.mobile.client.android.mail;end',
        ),
      );
      candidates.add(Uri.parse('ymail://'));
      candidates.add(Uri.parse('https://mail.yahoo.com'));
    }
  }

  // Generic mail app inboxes (Android system email, Gmail fallback, Apple Mail)
  candidates.addAll([
    Uri.parse(
      'intent:#Intent;action=android.intent.action.MAIN;category=android.intent.category.APP_EMAIL;end',
    ),
    Uri.parse(
      'intent:#Intent;action=android.intent.action.MAIN;package=com.google.android.gm;end',
    ),
    Uri.parse('message://'),
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
