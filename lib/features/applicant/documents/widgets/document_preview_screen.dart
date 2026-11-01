import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../api/api_error.dart';
import '../../../../components/common/app_status_panel.dart';
import '../../../../components/layout/screen_scaffold.dart';
import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../document_model.dart';
import '../documents_repository.dart';

typedef DocumentPdfBuilder = Widget Function(
  Uint8List bytes,
  VoidCallback onLoaded,
  ValueChanged<Object> onError,
);

class DocumentPreviewScreen extends ConsumerStatefulWidget {
  const DocumentPreviewScreen({super.key, required this.item, this.pdfBuilder});

  final DocumentDto item;
  final DocumentPdfBuilder? pdfBuilder;

  @override
  ConsumerState<DocumentPreviewScreen> createState() =>
      _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends ConsumerState<DocumentPreviewScreen> {
  Object? _error;
  PdfDocumentPreview? _pdf;
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
      _pdf = null;
    });
    try {
      final preview = await ref
          .read(documentsRepositoryProvider)
          .preview(widget.item.id);
      if (!mounted) return;
      switch (preview) {
        case PdfDocumentPreview():
          setState(() => _pdf = preview);
        case UrlDocumentPreview():
          final opened = await launchUrl(
            preview.url,
            mode: LaunchMode.inAppBrowserView,
          );
          if (!opened) throw const _CannotOpenPreview();
          if (mounted) context.pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  void _pdfLoaded() {
    if (mounted) setState(() => _loading = false);
  }

  void _pdfFailed(Object error) {
    if (!mounted) return;
    setState(() {
      _pdf = null;
      _loading = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      appBar: AppBar(title: Text(tr('documents.mobile.view'))),
      body: _pdf != null
          ? Stack(
              children: [
                widget.pdfBuilder?.call(_pdf!.bytes, _pdfLoaded, _pdfFailed) ??
                    _DocumentPdfView(
                      bytes: _pdf!.bytes,
                      onLoaded: _pdfLoaded,
                      onError: _pdfFailed,
                    ),
                if (_loading) const Center(child: CircularProgressIndicator()),
              ],
            )
          : Center(
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

class _DocumentPdfView extends StatefulWidget {
  const _DocumentPdfView({
    required this.bytes,
    required this.onLoaded,
    required this.onError,
  });

  final Uint8List bytes;
  final VoidCallback onLoaded;
  final ValueChanged<Object> onError;

  @override
  State<_DocumentPdfView> createState() => _DocumentPdfViewState();
}

class _DocumentPdfViewState extends State<_DocumentPdfView> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(widget.bytes),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PdfViewPinch(
    controller: _controller,
    backgroundDecoration: BoxDecoration(color: context.colors.background),
    onDocumentLoaded: (_) => widget.onLoaded(),
    onDocumentError: widget.onError,
  );
}
