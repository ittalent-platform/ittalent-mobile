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
import '../../../components/ui/app_badge.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_card.dart';
import '../../../components/ui/app_input.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_typography.dart';
import 'document_files.dart';
import 'document_access_policy.dart';
import 'document_model.dart';
import 'documents_constants.dart';
import 'documents_providers.dart';
import 'documents_repository.dart';

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
      DocumentFileFailure.io => 'documents.mobile.read',
    });
  }
  if (error is ApiError) {
    final key = switch (error.statusCode) {
      400 => 'invalid',
      401 => 'unauthorized',
      403 => 'forbidden',
      404 => 'notFound',
      502 => 'storage',
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

class _DocumentsScreenState extends ConsumerState<DocumentsScreen>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  final _uploadCancel = CancelToken();
  bool _destinationBusy = false;
  DocumentAccessOperation? _blockedOperation;
  DocumentAccessDecision? _blockedDecision;
  Timer? _debounce;
  SelectedDocument? _selected;
  DocumentType? _uploadType;
  Object? _uploadError;
  bool _busy = false;
  bool _uploading = false;
  double? _progress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _blockedOperation != null) {
      final operation = _blockedOperation!;
      ref
          .read(documentAccessPolicyProvider)
          .check(operation)
          .then((decision) {
            if (!mounted) return;
            setState(() {
              _blockedDecision = decision;
              if (decision.allowed) _blockedOperation = null;
            });
            if (decision.allowed) _toast(tr('documents.permissions.ready'));
          })
          .catchError((Object _) {
            // Keep the previous state; a failed status check cannot grant access.
          });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _search.dispose();
    _uploadCancel.cancel();
    super.dispose();
  }

  Future<bool> _authorize(
    DocumentAccessOperation operation,
    VoidCallback retry,
  ) async {
    final policy = ref.read(documentAccessPolicyProvider);
    var decision = await policy.check(operation);
    if (!mounted) return false;
    if (decision.status == DocumentAccessStatus.denied) {
      decision = await policy.request(operation);
      if (!mounted) return false;
    }
    if (decision.allowed) {
      setState(() {
        _blockedOperation = null;
        _blockedDecision = null;
      });
      return true;
    }
    setState(() {
      _blockedOperation = operation;
      _blockedDecision = decision;
    });
    final key = _permissionKey(decision.status, operation);
    final canRetry = decision.status == DocumentAccessStatus.denied;
    final canSettings =
        decision.settingsCanHelp &&
        (decision.status == DocumentAccessStatus.permanentlyDenied ||
            decision.status == DocumentAccessStatus.restricted);
    if (!mounted) return false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('documents.permissions.title')),
        content: Text(tr('documents.permissions.$key')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('documents.permissions.close')),
          ),
          if (canRetry)
            TextButton(
              key: const Key('documents_permission_retry'),
              onPressed: () {
                Navigator.pop(dialogContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) retry();
                });
              },
              child: Text(tr('documents.mobile.retry')),
            ),
          if (canSettings)
            TextButton(
              key: const Key('documents_permission_settings'),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final opened = await policy.openSettings();
                if (mounted && !opened) {
                  _toast(
                    tr('documents.permissions.settingsFailed'),
                    error: true,
                  );
                }
              },
              child: Text(tr('documents.permissions.openSettings')),
            ),
        ],
      ),
    );
    return false;
  }

  String _permissionKey(
    DocumentAccessStatus status,
    DocumentAccessOperation operation,
  ) => switch (status) {
    DocumentAccessStatus.denied =>
      operation == DocumentAccessOperation.uploadRead
          ? 'uploadDenied'
          : 'downloadDenied',
    DocumentAccessStatus.permanentlyDenied => 'permanentlyDenied',
    DocumentAccessStatus.restricted => 'restricted',
    _ => 'unsupported',
  };

  void _toast(String message, {bool error = false, VoidCallback? retry}) {
    showAppToast(
      ScaffoldMessenger.of(context),
      message,
      error: error,
      action: retry == null
          ? null
          : SnackBarAction(
              label: tr('documents.mobile.retry'),
              onPressed: retry,
            ),
    );
  }

  void _setQuery(DocumentType? type, String search) => ref
      .read(documentsQueryProvider.notifier)
      .update(DocumentsQuery(type: type, search: search.trim()));

  Future<void> _choose() async {
    if (_busy || _destinationBusy) return;
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
                  for (final type in DocumentType.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppButton(
                        key: Key('pick_${type.value}'),
                        size: AppButtonSize.lg,
                        text: tr(
                          type == DocumentType.cv
                              ? 'documents.mobile.uploadCv'
                              : 'documents.mobile.uploadCover',
                        ),
                        icon: const Icon(LucideIcons.fileUp),
                        variant: AppButtonVariant.outline,
                        onPressed: () => Navigator.pop(sheetContext, type),
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
      if (_destinationBusy) return;
      _destinationBusy = true;
      SelectedDocument? file;
      try {
        if (!await _authorize(DocumentAccessOperation.uploadRead, _choose)) {
          return;
        }
        file = await ref.read(documentFilesProvider).pick();
      } finally {
        _destinationBusy = false;
      }
      if (!mounted) return;
      if (file == null) {
        _toast(tr('documents.permissions.pickCancelled'));
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
    setState(() => _uploading = true);
    try {
      await ref
          .read(documentsRepositoryProvider)
          .upload(
            _selected!,
            _uploadType!,
            cancelToken: _uploadCancel,
            onProgress: (sent, total) {
              if (mounted) {
                setState(
                  () =>
                      _progress = total > 0 ? (sent / total).clamp(0, 1) : null,
                );
              }
            },
          );
      if (!mounted) return;
      ref.invalidate(documentsProvider);
      setState(() {
        _selected = null;
        _uploadError = null;
      });
      _toast(tr('documents.uploadedTitle'));
    } catch (error) {
      if (mounted) setState(() => _uploadError = error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _retryUpload() async {
    if (_busy || _destinationBusy) return;
    _destinationBusy = true;
    var ownsDialog = true;
    setState(() {
      _busy = true;
      _uploadError = null;
      _progress = null;
    });
    try {
      if (!await _authorize(DocumentAccessOperation.uploadRead, _retryUpload)) {
        return;
      }
      if (!mounted) return;
      _destinationBusy = false;
      ownsDialog = false;
      await _send();
    } finally {
      if (ownsDialog) _destinationBusy = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _uploadCard() => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _selected?.name ?? tr('documents.uploadFailedTitle'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body(fontWeight: FontWeight.w600),
        ),
        if (_selected != null) Text(_size(_selected!.size)),
        const SizedBox(height: 8),
        if (_uploading && _selected != null) ...[
          Text(tr('documents.uploading')),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _progress,
            color: context.colors.primary,
          ),
        ],
        if (_uploadError != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              documentError(_uploadError!),
              style: AppTypography.body(color: context.colors.destructive),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              if (_selected != null &&
                  _uploadError is! DocumentValidation &&
                  !(_uploadError is DocumentFileException &&
                      (_uploadError as DocumentFileException).failure ==
                          DocumentFileFailure.permissionDenied))
                AppButton(
                  size: AppButtonSize.lg,
                  text: tr('documents.mobile.retry'),
                  onPressed: _busy ? null : _retryUpload,
                ),
              AppButton(
                size: AppButtonSize.lg,
                text: tr('documents.mobile.chooseAgain'),
                variant: AppButtonVariant.outline,
                onPressed: _busy ? null : _choose,
              ),
            ],
          ),
        ],
      ],
    ),
  );

  String _size(int bytes) => bytes >= 1048576
      ? '${(bytes / 1048576).toStringAsFixed(1)} MiB'
      : '${(bytes / 1024).toStringAsFixed(1)} KiB';

  Widget _card(DocumentDto item) {
    final colors = context.colors;
    final cv = item.type == DocumentType.cv;
    return AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 52,
                decoration: BoxDecoration(
                  color: cv ? colors.statusPeachBg : colors.statusInfoBg,
                  borderRadius: AppRadius.inputRadius,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 18,
                      color: cv ? colors.primary : colors.statusInfoFg,
                    ),
                    Text(
                      tr(cv ? 'documents.typeCv' : 'documents.mobile.cl'),
                      style: AppTypography.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cv ? colors.primary : colors.statusInfoFg,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${tr(cv ? 'documents.typeCv' : 'documents.typeCoverLetter')} · ${_size(item.size)} · ${DateFormat.yMMMd(context.locale.toString()).format(item.createdAt.toLocal())}',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: colors.mutedForeground,
                      ),
                    ),
                    if (item.isDefault)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: AppBadge(
                          label: tr('documents.default'),
                          tone: BadgeTone.peach,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              ),
            );
          }
          return Column(
            children: [
              for (final item in data.result.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _card(item),
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
    return ScreenScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: tr('documents.mobile.back'),
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.profile);
            }
          },
        ),
        title: Text(tr('documents.title')),
        actions: [
          IconButton(
            tooltip: tr('documents.mobile.refresh'),
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => ref.invalidate(documentsProvider),
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
        onPressed: _busy ? null : _choose,
        child: const Icon(LucideIcons.plus),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          if (_blockedDecision != null &&
              !_blockedDecision!.allowed &&
              _blockedOperation != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Text(
                  tr(
                    'documents.permissions.${_permissionKey(_blockedDecision!.status, _blockedOperation!)}',
                  ),
                  style: AppTypography.body(color: context.colors.destructive),
                ),
              ),
            ),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final type in <DocumentType?>[
                  null,
                  ...DocumentType.values,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Semantics(
                      selected: query.type == type,
                      child: AppButton(
                        key: Key('filter_${type?.value ?? 'all'}'),
                        size: AppButtonSize.lg,
                        text: tr(
                          type == null
                              ? 'documents.mobile.all'
                              : 'documents.tabs.${type.value}',
                        ),
                        variant: query.type == type
                            ? AppButtonVariant.primary
                            : AppButtonVariant.outline,
                        onPressed: () {
                          _debounce?.cancel();
                          _setQuery(type, _search.text);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final refreshed = ref.refresh(documentsProvider.future);
                try {
                  await refreshed;
                } catch (_) {
                  /* Provider displays the error. */
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  if (_selected != null || _uploadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _uploadCard(),
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
