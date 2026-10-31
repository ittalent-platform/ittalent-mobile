import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../api/api_error.dart';
import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/common/app_toast.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_card.dart';
import '../../../components/ui/app_input.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'document_files.dart';
import 'document_formatters.dart';
import 'document_model.dart';
import 'documents_constants.dart';
import 'documents_providers.dart';
import 'documents_repository.dart';
import 'widgets/delete_document_sheet.dart';
import 'widgets/document_action_sheet.dart';
import 'widgets/document_card.dart';
import 'widgets/document_filter_chips.dart';
import 'widgets/document_preview_screen.dart';
import 'widgets/document_upload_card.dart';

String documentError(
  Object error, {
  String fallback = 'documents.uploadFailedMessage',
}) {
  if (error is DocumentValidation) return tr('documents.mobile.${error.key}');
  if (error is DocumentFileException) {
    return tr(switch (error.failure) {
      DocumentFileFailure.permissionDenied =>
        'documents.permissions.resourceDenied',
      DocumentFileFailure.unsupported => 'documents.permissions.unsupported',
      DocumentFileFailure.io =>
        fallback == 'documents.downloadFailedMessage'
            ? 'documents.permissions.saveFailed'
            : 'documents.mobile.read',
    });
  }
  if (error is ApiError) {
    final key = switch (error.statusCode) {
      400 => 'invalid',
      401 => 'unauthorized',
      403 => 'forbidden',
      404 => 'notFound',
      409 => 'conflict',
      502 || 503 => 'storage',
      _ => 'network',
    };
    return tr('documents.mobile.$key');
  }
  return tr(fallback);
}

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final _search = TextEditingController();
  final Map<String, CancelToken> _downloads = {};
  final Map<String, double?> _downloadProgress = {};
  final Map<String, String> _downloadPhase = {};
  final Set<String> _mutating = {};
  Timer? _debounce;
  SelectedDocument? _selected;
  DocumentType? _uploadType;
  Object? _uploadError;
  CancelToken? _uploadCancel;
  var _uploadGeneration = 0;
  var _busy = false;
  var _destinationBusy = false;
  var _uploading = false;
  double? _progress;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _uploadCancel?.cancel();
    for (final token in _downloads.values) {
      token.cancel();
    }
    super.dispose();
  }

  void _toast(
    String message, {
    bool error = false,
    String? actionLabel,
    VoidCallback? action,
  }) {
    showAppToast(
      ScaffoldMessenger.of(context),
      message,
      error: error,
      action: action == null || actionLabel == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: action),
    );
  }

  void _setQuery(DocumentType? type, String search) {
    ref
        .read(documentsQueryProvider.notifier)
        .update(DocumentsQuery(type: type, search: search.trim()));
  }

  void _invalidateDocumentCounts() => ref.invalidate(
    documentFilterCountsProvider(ref.read(documentsQueryProvider).search),
  );

  Future<void> _choose() async {
    if (_busy || _destinationBusy || _uploading) return;
    setState(() => _busy = true);
    try {
      FocusScope.of(context).unfocus();
      final type = await showModalBottomSheet<DocumentType>(
        context: context,
        backgroundColor: context.colors.card,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr('documents.mobile.sheetTitle'),
                    style: AppTypography.display(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(tr('documents.mobile.helper')),
                  const SizedBox(height: 16),
                  for (final choice in DocumentType.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppButton(
                        key: Key('pick_${choice.value}'),
                        size: AppButtonSize.lg,
                        text: tr(
                          choice == DocumentType.cv
                              ? 'documents.mobile.uploadCv'
                              : 'documents.mobile.uploadCover',
                        ),
                        icon: const Icon(LucideIcons.fileUp),
                        variant: AppButtonVariant.outline,
                        onPressed: () => Navigator.pop(sheetContext, choice),
                      ),
                    ),
                  AppButton(
                    size: AppButtonSize.lg,
                    text: tr('documents.mobile.cancel'),
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (type == null || !mounted) return;
      final file = await ref.read(documentFilesProvider).pick();
      if (!mounted) return;
      if (file == null) {
        _toast(tr('documents.mobile.pickCancelled'));
        return;
      }
      setState(() {
        _selected = file;
        _uploadType = type;
        _uploadError = null;
        _progress = null;
      });
      await _send();
    } catch (error) {
      if (mounted) setState(() => _uploadError = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final file = _selected;
    final type = _uploadType;
    if (file == null || type == null || _uploading) return;
    final generation = ++_uploadGeneration;
    final token = CancelToken();
    setState(() {
      _uploading = true;
      _uploadCancel = token;
      _uploadError = null;
      _progress = null;
    });
    try {
      final uploaded = await ref
          .read(documentsRepositoryProvider)
          .upload(
            file,
            type,
            cancelToken: token,
            onProgress: (sent, total) {
              if (mounted && generation == _uploadGeneration) {
                setState(
                  () =>
                      _progress = total > 0 ? (sent / total).clamp(0, 1) : null,
                );
              }
            },
          );
      if (!mounted || generation != _uploadGeneration) return;
      ref.invalidate(documentsProvider);
      _invalidateDocumentCounts();
      setState(() {
        _selected = null;
        _uploadError = null;
      });
      _toast(
        tr('documents.uploadedTitle'),
        actionLabel: uploaded.type == DocumentType.cv && !uploaded.isDefault
            ? tr('documents.mobile.setDefault')
            : null,
        action: uploaded.type == DocumentType.cv && !uploaded.isDefault
            ? () => _setDefault(uploaded)
            : null,
      );
    } catch (error) {
      if (mounted && generation == _uploadGeneration) {
        setState(() => _uploadError = error);
      }
    } finally {
      if (mounted && generation == _uploadGeneration) {
        setState(() {
          _uploading = false;
          _uploadCancel = null;
        });
      }
    }
  }

  void _cancelUpload() {
    final token = _uploadCancel;
    if (token == null || !_uploading) return;
    _uploadGeneration++;
    token.cancel();
    setState(() {
      _uploadCancel = null;
      _uploading = false;
      _selected = null;
      _uploadError = null;
      _progress = null;
    });
    _toast(tr('documents.mobile.uploadCancelled'));
  }

  Future<void> _retryUpload() async {
    if (_busy || _uploading || _selected == null) return;
    await _send();
  }

  Future<void> _download(DocumentDto item) async {
    if (_downloads.containsKey(item.id) || _destinationBusy) return;
    _destinationBusy = true;
    var ownsDestination = true;
    final cancel = CancelToken();
    setState(() {
      _downloads[item.id] = cancel;
      _downloadProgress[item.id] = null;
      _downloadPhase[item.id] = 'Choosing';
    });
    DocumentDestination? destination;
    try {
      final files = ref.read(documentFilesProvider);
      try {
        destination = await files.prepareDownload(
          documentFileName(null, item.fileName),
          item.mimeType,
        );
      } finally {
        _destinationBusy = false;
        ownsDestination = false;
      }
      if (!mounted) return;
      if (destination == null) {
        _toast(tr('documents.mobile.saveCancelled'));
        return;
      }
      setState(() => _downloadPhase[item.id] = 'Downloading');
      final file = await ref
          .read(documentsRepositoryProvider)
          .download(
            item,
            cancelToken: cancel,
            onProgress: (count, total) {
              if (mounted) {
                setState(
                  () => _downloadProgress[item.id] = total > 0
                      ? (count / total).clamp(0, 1)
                      : null,
                );
              }
            },
          );
      if (!mounted) return;
      setState(() => _downloadPhase[item.id] = 'Saving');
      final location = await destination.write(file);
      if (!mounted || location == null) return;
      _toast(
        tr(
          location.scheme == 'blob' || location.scheme == 'data'
              ? 'documents.mobile.browserSave'
              : 'documents.mobile.saved',
          namedArgs: {'location': location.toString()},
        ),
      );
    } catch (error) {
      if (mounted) {
        _toast(
          documentError(error, fallback: 'documents.downloadFailedMessage'),
          error: true,
          actionLabel: tr('documents.mobile.retry'),
          action: () => _download(item),
        );
      }
    } finally {
      if (ownsDestination) _destinationBusy = false;
      if (destination != null) {
        try {
          await destination.abort();
        } catch (_) {
          // Preserve the original transfer or write error.
        }
      }
      if (mounted) {
        setState(() {
          _downloads.remove(item.id);
          _downloadProgress.remove(item.id);
          _downloadPhase.remove(item.id);
        });
      }
    }
  }

  Future<void> _setDefault(DocumentDto item) async {
    if (item.type != DocumentType.cv || _mutating.contains(item.id)) return;
    setState(() => _mutating.add(item.id));
    try {
      await ref.read(documentsRepositoryProvider).setDefault(item.id);
      if (!mounted) return;
      ref.invalidate(documentsProvider);
      _toast(tr('documents.defaultDoneTitle'));
    } catch (error) {
      if (mounted) {
        _toast(
          documentError(error, fallback: 'documents.defaultFailedTitle'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _mutating.remove(item.id));
    }
  }

  Future<void> _delete(DocumentDto item) async {
    if (_mutating.contains(item.id)) return;
    final confirmed = await showDeleteDocumentSheet(context, item);
    if (!confirmed || !mounted) return;
    setState(() => _mutating.add(item.id));
    try {
      await ref.read(documentsRepositoryProvider).delete(item.id);
      if (!mounted) return;
      ref.invalidate(documentsProvider);
      _invalidateDocumentCounts();
      _toast(tr('documents.deletedTitle'));
    } catch (error) {
      if (mounted) {
        _toast(
          documentError(error, fallback: 'documents.deleteFailedTitle'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _mutating.remove(item.id));
    }
  }

  Future<void> _chooseAction(DocumentDto item) async {
    if (_mutating.contains(item.id) || _downloads.containsKey(item.id)) return;
    final action = await showDocumentActionSheet(context, item);
    if (!mounted || action == null) return;
    switch (action) {
      case DocumentMenuAction.view:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => DocumentPreviewScreen(item: item)),
        );
      case DocumentMenuAction.setDefault:
        await _setDefault(item);
      case DocumentMenuAction.download:
        await _download(item);
      case DocumentMenuAction.delete:
        await _delete(item);
    }
  }

  String _uploadErrorMessage() {
    final error = _uploadError!;
    if (error is DocumentValidation &&
        error.key == 'size' &&
        _selected != null) {
      return tr(
        'documents.mobile.size',
        namedArgs: {'size': formatDocumentSize(_selected!.size)},
      );
    }
    return documentError(error);
  }

  Widget _content(AsyncValue<DocumentsList> async, DocumentsQuery query) =>
      async.when(
        skipLoadingOnReload: false,
        loading: () => Column(
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(top: 12),
              child: AppCard(
                child: AppSkeleton(height: 64, width: double.infinity),
              ),
            ),
          ),
        ),
        error: (error, _) => Column(
          children: [
            AppErrorState(
              title: tr('documents.loadError'),
              message: documentError(error, fallback: 'documents.loadError'),
            ),
            AppButton(
              size: AppButtonSize.lg,
              text: tr('documents.mobile.retry'),
              onPressed: () => ref.invalidate(documentsProvider),
            ),
          ],
        ),
        data: (data) {
          if (data.result.items.isEmpty) {
            return AppEmptyState(
              icon: const Icon(LucideIcons.files),
              title: tr(
                query.search.isNotEmpty
                    ? 'documents.noMatchesTitle'
                    : query.type != null
                    ? 'documents.mobile.emptyType'
                    : 'documents.emptyTitle',
              ),
              description: tr(
                query.search.isNotEmpty
                    ? 'documents.noMatchesHint'
                    : 'documents.emptyHint',
                namedArgs: {'query': query.search},
              ),
            );
          }
          return Column(
            children: [
              for (final item in data.result.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DocumentCard(
                    item: item,
                    isBusy:
                        _downloads.containsKey(item.id) ||
                        _mutating.contains(item.id),
                    downloadProgress: _downloadProgress[item.id],
                    downloadPhase: _downloadPhase[item.id],
                    onAction: () => _chooseAction(item),
                  ),
                ),
              if (data.moreError != null)
                Text(
                  documentError(
                    data.moreError!,
                    fallback: 'documents.loadError',
                  ),
                ),
              if (data.result.page < data.result.totalPages)
                AppButton(
                  key: const Key('documents_more'),
                  size: AppButtonSize.lg,
                  text: tr(
                    data.moreError == null
                        ? 'documents.mobile.loadMore'
                        : 'documents.mobile.retry',
                  ),
                  isLoading: data.loadingMore,
                  variant: AppButtonVariant.outline,
                  onPressed: ref.read(documentsProvider.notifier).loadMore,
                ),
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(documentsQueryProvider);
    final async = ref.watch(documentsProvider);
    final counts = ref
        .watch(documentFilterCountsProvider(query.search))
        .asData
        ?.value;
    return ScreenScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: tr('documents.mobile.back'),
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.profile),
        ),
        title: Text(tr('documents.title')),
        actions: [
          IconButton(
            tooltip: tr('documents.mobile.refresh'),
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              ref.invalidate(documentsProvider);
              _invalidateDocumentCounts();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('documents_upload'),
        shape: const CircleBorder(),
        elevation: 0,
        tooltip: tr('documents.mobile.upload'),
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.primaryForeground,
        onPressed: _busy || _uploading ? null : _choose,
        child: const Icon(LucideIcons.plus),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          AppInput(
            controller: _search,
            inputFormatters: [
              LengthLimitingTextInputFormatter(DocumentConstants.searchLimit),
            ],
            hintText: tr('documents.searchPlaceholder'),
            prefixIcon: const Icon(LucideIcons.search, size: 18),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(
                DocumentConstants.debounce,
                () => _setQuery(ref.read(documentsQueryProvider).type, value),
              );
            },
          ),
          const SizedBox(height: 8),
          DocumentFilterChips(
            selectedType: query.type,
            counts: counts,
            onSelected: (type) {
              _debounce?.cancel();
              _setQuery(type, _search.text);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _invalidateDocumentCounts();
                try {
                  final refreshed = ref.refresh(documentsProvider.future);
                  await refreshed;
                } catch (_) {
                  // Provider renders the error state.
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 144),
                children: [
                  if (_selected != null || _uploadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DocumentUploadCard(
                        file: _selected,
                        uploading: _uploading,
                        progress: _progress,
                        errorMessage: _uploadError == null
                            ? null
                            : _uploadErrorMessage(),
                        canRetry:
                            _selected != null &&
                            _uploadError is! DocumentValidation &&
                            !(_uploadError is DocumentFileException &&
                                (_uploadError as DocumentFileException)
                                        .failure ==
                                    DocumentFileFailure.permissionDenied),
                        onRetry: _retryUpload,
                        onChooseAgain: _choose,
                        onCancel: _cancelUpload,
                      ),
                    ),
                  _content(async, query),
                  const SizedBox(height: 12),
                  Text(
                    tr('documents.mobile.helper'),
                    style: AppTypography.body(
                      fontSize: 12,
                      color: context.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
