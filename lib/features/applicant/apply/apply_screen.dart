import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../api/api_error.dart';
import '../../../auth/auth_notifier.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/common/app_toast.dart';
import '../../../components/ui/app_badge.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_typography.dart';
import 'apply_attempts.dart';
import 'apply_constants.dart';
import 'apply_files.dart';
import 'apply_models.dart';
import 'apply_providers.dart';
import 'apply_repository.dart';
import 'widgets/apply_bottom_bar.dart';
import 'widgets/apply_certificates_card.dart';
import 'widgets/apply_discard_sheet.dart';
import 'widgets/apply_documents_card.dart';
import 'widgets/apply_documents_section.dart';
import 'widgets/apply_header.dart';
import 'widgets/apply_job_tile.dart';
import 'widgets/apply_message_field.dart';
import 'widgets/apply_notice_banner.dart';
import 'widgets/apply_skeleton.dart';
import 'widgets/apply_status_view.dart';

/// UC-BJOB-03: apply to a job in two steps (the CV and an optional cover
/// letter, then a look over the documents, the certificates and a note),
/// followed by a page that says the application was sent. The pages that stop
/// an application (email not verified, job closed, already applied) take the
/// place of the steps.
///
/// What the applicant chose is kept here, in the screen: it lives as long as
/// the flow does, and nothing is sent until "Submit application".
class ApplyScreen extends ConsumerStatefulWidget {
  const ApplyScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  final TextEditingController _message = TextEditingController();

  int _step = 1;
  String? _cvId;

  /// Null is "No cover letter".
  String? _coverLetterId;

  /// The certificates ticked; null until the applicant changes one, which
  /// leaves the suggested ones ticked.
  Set<String>? _ticked;

  /// Documents uploaded in this flow, shown at once without waiting for the
  /// list to be read again.
  final Map<String, List<ApplyDocument>> _uploaded = {
    ApplyConstants.typeCv: [],
    ApplyConstants.typeCoverLetter: [],
  };

  /// The kind of document being uploaded.
  String? _uploading;
  bool _submitting = false;

  /// True once an attempt got no answer (no connection, a timeout, a 5xx): the
  /// application may or may not have been created. If the next attempt is then
  /// refused as "already applied", the API is asked what became of the first
  /// one (see [_sentEarlier]) rather than telling the applicant they applied
  /// twice. It is never reset: a later error does not undo the doubt.
  bool _outcomeUnknown = false;
  bool _resending = false;
  String? _submittedId;
  bool _submitted = false;
  ApplyBlock? _block;
  ApplyNotice? _notice;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  // ---- data -------------------------------------------------------------

  AsyncValue<List<ApplyDocument>> _documents(String type) {
    final fetched = ref.watch(applyDocumentsProvider(type));
    final extra = _uploaded[type] ?? const <ApplyDocument>[];
    if (extra.isEmpty) return fetched;
    return fetched.whenData(
      (list) => [
        ...list,
        ...extra.where((added) => !list.any((e) => e.id == added.id)),
      ]..sort(ApplyDocument.defaultFirst),
    );
  }

  ApplyDocument? _find(List<ApplyDocument> documents, String? id) {
    for (final document in documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  Set<String> _tickedIds(List<ApplyCertificate> certificates) {
    final ids = {for (final item in certificates) item.id};
    final chosen =
        _ticked ??
        {
          for (final item in certificates)
            if (item.suggested) item.id,
        }.take(ApplyConstants.maxCertificates).toSet();
    return chosen.intersection(ids);
  }

  // ---- leaving ----------------------------------------------------------

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.jobDetail(widget.jobId));
    }
  }

  void _keepBrowsing() => context.go(AppRoutes.jobs);

  Future<void> _confirmDiscard(String company) async {
    final discard = await showApplyDiscardSheet(context, company);
    if (discard && mounted) _close();
  }

  /// The back button of the app bar and of the phone: a step back, or out.
  Future<void> _back({required bool inFlow, required String company}) async {
    if (_submitting) return;
    if (_submitted) {
      _keepBrowsing();
    } else if (!inFlow) {
      _close();
    } else if (_step == 2) {
      setState(() {
        _step = 1;
        _notice = null;
      });
    } else {
      await _confirmDiscard(company);
    }
  }

  // ---- step 1 -----------------------------------------------------------

  void _selectCv(String? id) => setState(() {
    _cvId = id;
    _notice = null;
  });

  void _selectCoverLetter(String? id) => setState(() => _coverLetterId = id);

  void _continue(List<ApplyDocument> cvs) {
    if (ApplyDocument.chosen(cvs, _cvId) == null) {
      setState(() => _notice = const ApplyNotice('apply.errors.chooseCv'));
      return;
    }
    setState(() {
      _cvId = ApplyDocument.chosen(cvs, _cvId);
      _notice = null;
      _step = 2;
    });
  }

  void _showProblem(ApplyFileException error) {
    final key = switch (error.problem) {
      ApplyFileProblem.tooLarge => 'apply.upload.tooLarge',
      ApplyFileProblem.wordFile => 'apply.upload.wordFile',
      ApplyFileProblem.notPdf => 'apply.upload.notPdf',
      ApplyFileProblem.empty => 'apply.upload.empty',
      ApplyFileProblem.unreadable => 'apply.upload.unreadable',
    };
    setState(() {
      _uploading = null;
      _notice = ApplyNotice(
        key,
        args: {
          'name': error.file.name,
          'size': formatFileSize(error.file.size),
        },
      );
    });
  }

  Future<void> _upload(String type) async {
    if (_uploading != null || _submitting) return;
    final messenger = ScaffoldMessenger.of(context);
    final picker = ref.read(applyFilesProvider);
    final repository = ref.read(applyRepositoryProvider);
    setState(() => _notice = null);

    ApplyPickedFile? picked;
    try {
      picked = await picker.pick();
    } on ApplyFileException catch (error) {
      if (mounted) _showProblem(error);
      return;
    }
    if (picked == null || !mounted) return;
    // A copy that cannot be null, for the closures below.
    final file = picked;

    setState(() => _uploading = type);
    try {
      final document = await repository.upload(file, type);
      if (!mounted) return;
      ref.invalidate(applyDocumentsProvider(type));
      setState(() {
        _uploaded[type] = [...?_uploaded[type], document];
        if (type == ApplyConstants.typeCv) {
          _cvId = document.id;
        } else {
          _coverLetterId = document.id;
        }
        _uploading = null;
      });
      showAppToast(messenger, tr('apply.uploaded'));
    } on ApplyFileException catch (error) {
      if (mounted) _showProblem(error);
    } on ApiError catch (error) {
      if (!mounted) return;
      setState(() {
        _uploading = null;
        _notice = error.statusCode == null
            ? const ApplyNotice('apply.errors.offline', offline: true)
            : ApplyNotice('apply.upload.failed', args: {'name': file.name});
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _uploading = null;
        _notice = ApplyNotice('apply.upload.failed', args: {'name': file.name});
      });
    }
  }

  // ---- step 2 -----------------------------------------------------------

  void _toggleCertificate(
    ApplyCertificate item,
    List<ApplyCertificate> certificates,
  ) {
    final ticked = {..._tickedIds(certificates)};
    if (ticked.contains(item.id)) {
      ticked.remove(item.id);
    } else if (ticked.length >= ApplyConstants.maxCertificates) {
      setState(
        () => _notice = const ApplyNotice(
          'apply.errors.tooManyCertificates',
          tone: ApplyNoticeTone.warning,
        ),
      );
      return;
    } else {
      ticked.add(item.id);
    }
    setState(() {
      _ticked = ticked;
      _notice = null;
    });
  }

  Future<void> _submit({
    required ApplyJob job,
    required String cvId,
    required String? coverLetterId,
    required List<String> certificateIds,
  }) async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    final repository = ref.read(applyRepositoryProvider);
    final attempts = ref.read(applyAttemptsProvider);
    final submitted = ref.read(applicationSubmittedProvider.notifier);
    // What is being sent, as an application is later recognised by.
    final fingerprint = applyFingerprint(
      jobId: job.id,
      cvId: cvId,
      coverLetterId: coverLetterId,
      message: _message.text,
      certificateIds: certificateIds,
    );
    setState(() {
      _submitting = true;
      _notice = null;
    });
    try {
      // One key names this attempt for as long as its outcome is unknown, so
      // that sending again (after a lost answer, even after the app was
      // closed) gets the application the first send created, not a second.
      final key = await attempts.keyFor(
        jobId: job.id,
        fingerprint: fingerprint,
      );
      final id = await repository.submit(
        jobId: job.id,
        cvId: cvId,
        coverLetterId: coverLetterId,
        message: _message.text,
        certificateIds: certificateIds,
        idempotencyKey: key,
      );
      await attempts.done(job.id);
      // The lists that show applications must read again, even if this
      // screen has gone by now.
      submitted.signal();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
        _submittedId = id;
      });
    } on Object catch (error) {
      // A clear refusal means nothing was created, so this attempt is over.
      // Any other failure may hide an application that was created: the key
      // stays for the next send.
      if (_isRefusal(error)) await attempts.done(job.id);
      if (!mounted) return;
      final earlier = await _sentEarlier(error, job.id, fingerprint);
      if (!mounted) return;
      if (earlier != null) {
        // The first attempt did reach the API, only its answer was lost: the
        // application exists and holds what is being sent now, so this ends
        // as a success, as the first one would have.
        submitted.signal();
        setState(() {
          _submitting = false;
          _submitted = true;
          _submittedId = earlier.id;
        });
        return;
      }
      _submitFailed(error, job);
    }
  }

  /// Whether the API answered "no" for good: a 4xx, other than a timeout. A
  /// 5xx, a timeout or no answer at all leaves it open whether the
  /// application was created.
  bool _isRefusal(Object error) {
    if (error is! ApiError) return false;
    final status = error.statusCode;
    return status != null &&
        status >= ApplyConstants.statusBadRequest &&
        status < ApplyConstants.statusServerError &&
        status != ApplyConstants.statusRequestTimeout;
  }

  /// The application that an earlier attempt, whose answer never came, did
  /// create: set when this attempt is refused as "already applied", the
  /// applicant has a live application for the job (they could not have opened
  /// this page with one) and that application holds exactly what is being
  /// sent now ([fingerprint]). An application that holds something else, for
  /// instance the CV or the note as they were before the applicant changed
  /// them, is not what they just sent, and is not reported as such. Null for
  /// any other failure.
  Future<PreviousApplication?> _sentEarlier(
    Object error,
    String jobId,
    String fingerprint,
  ) async {
    if (!_outcomeUnknown ||
        error is! ApiError ||
        error.code != ApplyConstants.codeAlreadyApplied) {
      return null;
    }
    try {
      final repository = ref.read(applyRepositoryProvider);
      final previous = await repository.previous(jobId);
      if (previous == null ||
          previous.id.isEmpty ||
          applyBlockFor(previous) != ApplyBlock.alreadyApplied) {
        return null;
      }
      final held = await repository.fingerprintOf(previous.id, jobId);
      return held == fingerprint ? previous : null;
    } on Object {
      return null;
    }
  }

  void _submitFailed(Object error, ApplyJob job) {
    final api = error is ApiError ? error : null;
    final code = api?.code;
    final block = applyBlockOf(code);
    final status = api?.statusCode;
    if (api == null || status == null || status >= 500) {
      _outcomeUnknown = true;
    }
    setState(() => _submitting = false);
    if (block != null) {
      if (block == ApplyBlock.alreadyApplied ||
          block == ApplyBlock.applyAgainNotAllowed) {
        ref.invalidate(previousApplicationProvider(widget.jobId));
      }
      setState(() => _block = block);
      return;
    }
    final ApplyNotice notice;
    switch (code) {
      case ApplyConstants.codeInvalidCv:
        ref.invalidate(applyDocumentsProvider(ApplyConstants.typeCv));
        _uploaded[ApplyConstants.typeCv]?.clear();
        _cvId = null;
        _step = 1;
        notice = const ApplyNotice('apply.errors.cvUnavailable');
      case ApplyConstants.codeInvalidCoverLetter:
        ref.invalidate(applyDocumentsProvider(ApplyConstants.typeCoverLetter));
        _uploaded[ApplyConstants.typeCoverLetter]?.clear();
        _coverLetterId = null;
        _step = 1;
        notice = const ApplyNotice('apply.errors.coverLetterUnavailable');
      case ApplyConstants.codeCertificateUnavailable:
        ref.invalidate(applyCertificatesProvider);
        notice = const ApplyNotice(
          'applications.applyCertificates.unavailable',
        );
      case ApplyConstants.codePositionFilled:
        notice = ApplyNotice(
          'apply.errors.positionFilled',
          args: {'company': job.companyName},
          tone: ApplyNoticeTone.warning,
        );
      case ApplyConstants.codeAccountNotActive:
        notice = const ApplyNotice('apply.errors.accountNotActive');
      default:
        // "Nothing was sent" is only true of a clear refusal. After a 5xx
        // the application may exist, so the notice does not claim otherwise
        // (a retry then finds it, see [_sentEarlier]).
        if (api != null && status == null) {
          notice = const ApplyNotice('apply.errors.offline', offline: true);
        } else if (status != null && status >= 500) {
          notice = const ApplyNotice('apply.errors.unconfirmed');
        } else {
          notice = const ApplyNotice('apply.errors.submitFailed');
        }
    }
    setState(() => _notice = notice);
  }

  Future<void> _resend() async {
    final email = ref.read(authNotifierProvider).email;
    if (_resending || email == null || email.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final auth = ref.read(authNotifierProvider.notifier);
    setState(() => _resending = true);
    final sent = await auth.resendVerificationEmail(email);
    if (!mounted) return;
    setState(() => _resending = false);
    showAppToast(
      messenger,
      tr(
        sent
            ? 'apply.blocked.emailNotVerified.resent'
            : 'apply.blocked.emailNotVerified.resendFailed',
      ),
      error: !sent,
    );
  }

  // ---- pages ------------------------------------------------------------

  Widget _outlineButton(
    String text,
    VoidCallback onPressed, {
    bool loading = false,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: AppRadius.buttonRadius,
      ),
      child: AppButton(
        text: text,
        variant: AppButtonVariant.outline,
        size: AppButtonSize.lg,
        isFullWidth: true,
        isLoading: loading,
        onPressed: onPressed,
      ),
    );
  }

  Widget _frame({
    required Widget header,
    required Widget body,
    Widget? bottom,
  }) {
    // The bar is the Scaffold's own bottom bar, so a toast (a CV was
    // uploaded) floats above it instead of covering the button.
    return Scaffold(
      backgroundColor: context.colors.background,
      bottomNavigationBar: bottom,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            header,
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _closeHeader({
    int? step,
    required VoidCallback onBack,
    bool back = false,
  }) {
    return ApplyHeader(
      leading: back ? LucideIcons.chevronLeft : LucideIcons.x,
      tooltip: tr(back ? 'actions.back' : 'actions.close'),
      onLeading: onBack,
      step: step,
    );
  }

  Widget _blockedPage(ApplyBlock block, PreviousApplication? previous) {
    final String? reference = previous == null || previous.id.isEmpty
        ? null
        : ApplyConstants.displayId(previous.id);
    void viewApplication() => context.go(
      previous == null || previous.id.isEmpty
          ? AppRoutes.myApplications
          : AppRoutes.applicationDetail(previous.id),
    );
    final view = switch (block) {
      ApplyBlock.emailNotVerified => ApplyStatusView(
        icon: LucideIcons.mail,
        tone: BadgeTone.warning,
        title: tr('apply.blocked.emailNotVerified.title'),
        body: TextSpan(text: _emailBody()),
        actions: [
          _outlineButton(
            tr('apply.blocked.emailNotVerified.resend'),
            _resend,
            loading: _resending,
          ),
        ],
      ),
      ApplyBlock.jobClosed => ApplyStatusView(
        icon: LucideIcons.lock,
        tone: BadgeTone.error,
        title: tr('apply.blocked.jobClosed.title'),
        body: TextSpan(text: tr('apply.blocked.jobClosed.body')),
        actions: [
          _outlineButton(tr('apply.blocked.jobClosed.action'), _keepBrowsing),
        ],
      ),
      ApplyBlock.alreadyApplied => ApplyStatusView(
        icon: LucideIcons.circleCheck,
        tone: BadgeTone.info,
        title: tr('apply.blocked.alreadyApplied.title'),
        body: TextSpan(
          text: reference == null
              ? tr('apply.blocked.alreadyApplied.bodyUnknown')
              : tr(
                  'apply.blocked.alreadyApplied.body',
                  namedArgs: {'id': reference},
                ),
        ),
        actions: [
          _outlineButton(
            tr('apply.blocked.alreadyApplied.action'),
            viewApplication,
          ),
        ],
      ),
      ApplyBlock.applyAgainNotAllowed => ApplyStatusView(
        icon: LucideIcons.circleAlert,
        tone: BadgeTone.warning,
        title: tr('apply.blocked.limit.title'),
        body: TextSpan(text: tr('apply.blocked.limit.body')),
        actions: [
          _outlineButton(
            tr('apply.blocked.alreadyApplied.action'),
            viewApplication,
          ),
        ],
      ),
    };
    return _frame(
      header: _closeHeader(onBack: _close),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: view,
        ),
      ),
    );
  }

  String _emailBody() {
    final email = ref.read(authNotifierProvider).email;
    return email == null || email.isEmpty
        ? tr('apply.blocked.emailNotVerified.bodyNoEmail')
        : tr(
            'apply.blocked.emailNotVerified.body',
            namedArgs: {'email': email},
          );
  }

  InlineSpan _successBody(String company, String? reference) {
    final colors = context.colors;
    if (reference == null) {
      return TextSpan(
        text: tr('apply.submitted.bodyNoId', namedArgs: {'company': company}),
      );
    }
    final text = tr(
      'apply.submitted.body',
      namedArgs: {'company': company, 'id': reference},
    );
    final at = text.indexOf(reference);
    if (at < 0) return TextSpan(text: text);
    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, at)),
        TextSpan(
          text: reference,
          style: AppTypography.mono(
            fontSize: 15.5,
            fontWeight: FontWeight.w400,
            height: 1.55,
            color: colors.mutedForeground,
          ),
        ),
        TextSpan(text: text.substring(at + reference.length)),
      ],
    );
  }

  /// The page that says the application was sent. [id] is the application the
  /// API answered with, or the one found for an attempt whose answer was lost.
  /// [company] may be blank, when neither the job nor the application names it.
  Widget _successPage(String company, String? id) {
    final reference = id == null || id.isEmpty
        ? null
        : ApplyConstants.displayId(id);
    final who = company.isEmpty ? tr('apply.submitted.employer') : company;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ApplyStatusView(
                    icon: LucideIcons.circleCheck,
                    tone: BadgeTone.success,
                    title: tr('apply.submitted.title'),
                    body: _successBody(who, reference),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    text: tr('apply.submitted.view'),
                    size: AppButtonSize.lg,
                    isFullWidth: true,
                    onPressed: () => context.go(
                      id == null || id.isEmpty
                          ? AppRoutes.myApplications
                          : AppRoutes.applicationDetail(id),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    text: tr('apply.submitted.browse'),
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.lg,
                    isFullWidth: true,
                    onPressed: _keepBrowsing,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The "no CV yet" page: a CV is needed, so the step is this one action.
  Widget _noCv(bool uploading) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            LucideIcons.file,
            size: 26,
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          tr('apply.noCv.title'),
          textAlign: TextAlign.center,
          style: AppTypography.body(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          tr('apply.noCv.body'),
          textAlign: TextAlign.center,
          style: AppTypography.body(
            fontSize: 14.5,
            height: 1.5,
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: AppButton(
            text: tr('apply.noCv.action'),
            icon: const Icon(LucideIcons.upload),
            size: AppButtonSize.lg,
            isLoading: uploading,
            onPressed: () => _upload(ApplyConstants.typeCv),
          ),
        ),
      ],
    );
  }

  Widget _stepOne(
    ApplyJob job,
    AsyncValue<List<ApplyDocument>> cvs,
    AsyncValue<List<ApplyDocument>> letters,
    ApplyNotice? info,
  ) {
    final cvList = cvs.value;
    final noCv = cvList != null && cvList.isEmpty;
    final body = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ApplyJobTile(job: job),
          if (info != null) ...[
            const SizedBox(height: 12),
            ApplyNoticeBanner(notice: info),
          ],
          if (noCv) ...[
            if (_notice != null) ...[
              const SizedBox(height: 12),
              ApplyNoticeBanner(notice: _notice!),
            ],
            const SizedBox(height: 48),
            _noCv(_uploading == ApplyConstants.typeCv),
          ] else ...[
            const SizedBox(height: 20),
            ApplyDocumentsSection(
              title: tr('apply.cv'),
              isRequired: true,
              documents: cvs,
              selectedId: ApplyDocument.chosen(cvList ?? const [], _cvId),
              onSelect: _selectCv,
              uploadTitle: tr('apply.uploadCv'),
              uploading: _uploading == ApplyConstants.typeCv,
              onUpload: () => _upload(ApplyConstants.typeCv),
              onRetry: () =>
                  ref.invalidate(applyDocumentsProvider(ApplyConstants.typeCv)),
              defaultLabel: tr('apply.defaultCv'),
            ),
            const SizedBox(height: 22),
            ApplyDocumentsSection(
              title: tr('apply.coverLetter'),
              documents: letters,
              selectedId: _find(letters.value ?? const [], _coverLetterId)?.id,
              noneTitle: tr('apply.noCoverLetter'),
              onSelect: _selectCoverLetter,
              uploadTitle: tr('apply.uploadCoverLetter'),
              uploading: _uploading == ApplyConstants.typeCoverLetter,
              onUpload: () => _upload(ApplyConstants.typeCoverLetter),
              onRetry: () => ref.invalidate(
                applyDocumentsProvider(ApplyConstants.typeCoverLetter),
              ),
              defaultLabel: tr('apply.defaultCoverLetter'),
            ),
          ],
        ],
      ),
    );
    return _frame(
      header: _closeHeader(
        step: 1,
        onBack: () => _back(inFlow: true, company: job.companyName),
      ),
      body: body,
      bottom: noCv
          ? null
          : ApplyBottomBar(
              notice: _notice,
              button: AppButton(
                text: tr('apply.continue'),
                size: AppButtonSize.lg,
                isFullWidth: true,
                onPressed: cvList == null || _uploading != null
                    ? null
                    : () => _continue(cvList),
              ),
            ),
    );
  }

  Widget _certificates(AsyncValue<List<ApplyCertificate>> certificates) {
    return certificates.when(
      skipLoadingOnReload: true,
      loading: () =>
          AppSkeleton(height: 120, borderRadius: AppRadius.cardRadius),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ApplyNoticeBanner(
            notice: ApplyNotice('apply.errors.loadCertificates'),
          ),
          TextButton.icon(
            onPressed: () => ref.invalidate(applyCertificatesProvider),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(tr('errorState.retry')),
          ),
        ],
      ),
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : ApplyCertificatesCard(
              certificates: items,
              ticked: _tickedIds(items),
              now: DateTime.now(),
              onToggle: (item) => _toggleCertificate(item, items),
            ),
    );
  }

  Widget _stepTwo(
    ApplyJob job,
    ApplyDocument cv,
    ApplyDocument? coverLetter,
    AsyncValue<List<ApplyCertificate>> certificates,
    ApplyNotice? info,
  ) {
    final items = certificates.value;
    final ticked = items == null ? const <String>{} : _tickedIds(items);
    final body = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ApplyJobTile(job: job),
          const SizedBox(height: 12),
          if (info != null) ...[
            ApplyNoticeBanner(notice: info),
            const SizedBox(height: 12),
          ],
          ApplyDocumentsCard(
            cv: cv,
            coverLetter: coverLetter,
            onChange: () => setState(() {
              _step = 1;
              _notice = null;
            }),
          ),
          const SizedBox(height: 12),
          _certificates(certificates),
          if (items == null || items.isNotEmpty) const SizedBox(height: 12),
          ApplyMessageField(
            controller: _message,
            company: job.companyName,
            enabled: !_submitting,
          ),
          const SizedBox(height: 12),
          Text(
            tr('apply.footnote'),
            style: AppTypography.body(
              fontSize: 13.5,
              height: 1.5,
              color: context.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
    // The links that go with the application are a choice the applicant made
    // on what they saw: nothing is sent until that list is read (again, after
    // a failure or a refresh), or a link could be dropped without a word.
    final ready =
        certificates.hasValue &&
        !certificates.hasError &&
        !certificates.isLoading;
    return _frame(
      header: _closeHeader(
        step: 2,
        back: true,
        onBack: () => _back(inFlow: true, company: job.companyName),
      ),
      body: body,
      bottom: ApplyBottomBar(
        notice: _notice,
        button: AppButton(
          text: tr(_submitting ? 'apply.submitting' : 'apply.submit'),
          size: AppButtonSize.lg,
          isFullWidth: true,
          onPressed: _submitting || !ready
              ? null
              : () => _submit(
                  job: job,
                  cvId: cv.id,
                  coverLetterId: coverLetter?.id,
                  certificateIds: ticked.toList(),
                ),
        ),
      ),
    );
  }

  ApplyNotice? _withdrewNotice(PreviousApplication? previous) {
    final at = previous?.withdrawnAt;
    if (previous == null || !previous.canApplyAgain || at == null) return null;
    return ApplyNotice(
      'apply.withdrewEarlier',
      args: {
        'date': DateFormat(
          'd MMM',
          Localizations.localeOf(context).toString(),
        ).format(at.toLocal()),
      },
      tone: ApplyNoticeTone.info,
    );
  }

  Widget _loading() => _frame(
    header: _closeHeader(step: 1, onBack: _close),
    body: const ApplySkeleton(),
  );

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(applyJobProvider(widget.jobId));
    final previous = ref.watch(previousApplicationProvider(widget.jobId));
    // An application found for an attempt whose answer was lost ends as that
    // attempt would have (BR-APP-009): the lists that show applications must
    // read again.
    ref.listen(previousApplicationProvider(widget.jobId), (_, next) {
      if (next.value?.sentByAttempt ?? false) {
        ref.read(applicationSubmittedProvider.notifier).signal();
      }
    });
    final company = jobAsync.value?.companyName ?? '';

    final Widget page;
    final bool inFlow;
    final loaded = jobAsync.value;
    final foundSent = previous.value?.sentByAttempt ?? false;
    final lookingUp = previous.isLoading && !previous.hasValue;
    if (_submitted || foundSent) {
      // An application that was sent is a fact about the application, not
      // about the job: it is reported even when the job cannot be read any
      // more because it closed since (BR-APP-009). The company then comes
      // from the application itself.
      inFlow = false;
      page = _successPage(
        firstNonBlank([loaded?.companyName, previous.value?.companyName]),
        _submittedId ?? previous.value?.id,
      );
    } else if (jobAsync.hasError && loaded == null) {
      inFlow = false;
      final error = jobAsync.error;
      final closed =
          error is ApiError &&
          (error.statusCode == ApplyConstants.statusNotFound ||
              error.statusCode == ApplyConstants.statusBadRequest);
      if (closed && lookingUp) {
        // The applicant may have sent this application before the job
        // closed: not "closed" until the application was looked up.
        page = _loading();
      } else if (closed) {
        page = _blockedPage(ApplyBlock.jobClosed, null);
      } else {
        page = _frame(
          header: _closeHeader(onBack: _close),
          body: AppErrorState(
            title: tr('apply.errors.loadJobTitle'),
            message: tr('apply.errors.loadJobBody'),
            retryText: tr('errorState.retry'),
            onRetry: () {
              ref.invalidate(applyJobProvider(widget.jobId));
              // What the applicant sent before is looked up again too: it
              // could not be, if the job could not be read for want of a
              // connection.
              ref.invalidate(previousApplicationProvider(widget.jobId));
            },
          ),
        );
      }
    } else if (loaded == null || lookingUp) {
      inFlow = false;
      page = _loading();
    } else {
      final block = _block ?? applyBlockFor(previous.value);
      if (block != null || !loaded.isOpen(DateTime.now())) {
        inFlow = false;
        page = _blockedPage(block ?? ApplyBlock.jobClosed, previous.value);
      } else {
        inFlow = true;
        final cvs = _documents(ApplyConstants.typeCv);
        final letters = _documents(ApplyConstants.typeCoverLetter);
        final cv = _find(
          cvs.value ?? const [],
          ApplyDocument.chosen(cvs.value ?? const [], _cvId),
        );
        final info = _withdrewNotice(previous.value);
        if (_step == 2 && cv != null) {
          page = _stepTwo(
            loaded,
            cv,
            _find(letters.value ?? const [], _coverLetterId),
            ref.watch(applyCertificatesProvider),
            info,
          );
        } else {
          page = _stepOne(loaded, cvs, letters, info);
        }
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(inFlow: inFlow, company: company);
      },
      child: page,
    );
  }
}
