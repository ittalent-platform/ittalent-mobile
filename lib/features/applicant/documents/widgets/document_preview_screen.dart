import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../api/api_error.dart';
import '../../../../components/common/app_status_panel.dart';
import '../../../../components/layout/screen_scaffold.dart';
import '../../../../components/ui/app_button.dart';
import '../document_model.dart';
import '../documents_repository.dart';

class DocumentPreviewScreen extends ConsumerStatefulWidget {
  const DocumentPreviewScreen({super.key, required this.item});

  final DocumentDto item;

  @override
  ConsumerState<DocumentPreviewScreen> createState() =>
      _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends ConsumerState<DocumentPreviewScreen> {
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = await ref
          .read(documentsRepositoryProvider)
          .preview(widget.item.id);
      final opened = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
      if (!opened) throw const _CannotOpenPreview();
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      appBar: AppBar(title: Text(tr('documents.mobile.view'))),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(16),
                child: _failurePanel(),
              ),
      ),
    );
  }

  Widget _failurePanel() {
    final expired =
        _error is ApiError && (_error as ApiError).statusCode == 410;
    final missing =
        _error is ApiError && (_error as ApiError).statusCode == 404;
    final key = expired
        ? 'expired'
        : missing
        ? 'notFound'
        : 'cannotOpen';
    return AppStatusPanel(
      title: tr('documents.preview.$key.title'),
      description: tr('documents.preview.$key.description'),
      icon: Icon(
        expired || missing ? LucideIcons.clock3 : LucideIcons.fileWarning,
      ),
      actions: AppButton(
        text: tr('documents.mobile.retry'),
        size: AppButtonSize.lg,
        isFullWidth: true,
        onPressed: _open,
      ),
    );
  }
}

class _CannotOpenPreview implements Exception {
  const _CannotOpenPreview();
}
