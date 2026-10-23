import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DocumentAccessOperation { uploadRead, downloadWrite }

enum DocumentAccessStatus {
  granted,
  notRequired,
  denied,
  permanentlyDenied,
  restricted,
  unsupported,
}

class DocumentAccessDecision {
  const DocumentAccessDecision(this.status, {this.settingsCanHelp = false});
  final DocumentAccessStatus status;
  final bool settingsCanHelp;

  bool get allowed =>
      status == DocumentAccessStatus.granted ||
      status == DocumentAccessStatus.notRequired;
}

/// SAF and platform document pickers grant access to the selected resource.
/// There is no storage runtime permission to request for these operations.
class DocumentAccessPolicy {
  static const _channel = MethodChannel(
    'com.example.ittalent_mobile/documents',
  );

  Future<DocumentAccessDecision> check(
    DocumentAccessOperation operation,
  ) async {
    if (kIsWeb) {
      return const DocumentAccessDecision(DocumentAccessStatus.notRequired);
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => const DocumentAccessDecision(
        DocumentAccessStatus.notRequired,
      ),
      TargetPlatform.fuchsia => const DocumentAccessDecision(
        DocumentAccessStatus.unsupported,
      ),
    };
  }

  /// Available to platform adapters that actually require a runtime grant.
  /// The current SAF/Files/browser adapters never call this in production.
  Future<DocumentAccessDecision> request(DocumentAccessOperation operation) =>
      check(operation);

  Future<bool> openSettings() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        return await _channel.invokeMethod<bool>('openSettings') ?? false;
      } on PlatformException {
        return false;
      } on MissingPluginException {
        return false;
      }
    }
    return false;
  }
}

final documentAccessPolicyProvider = Provider<DocumentAccessPolicy>(
  (ref) => DocumentAccessPolicy(),
);
