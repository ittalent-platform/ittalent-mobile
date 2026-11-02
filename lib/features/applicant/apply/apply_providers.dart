import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/auth_notifier.dart';
import 'apply_constants.dart';
import 'apply_models.dart';
import 'apply_repository.dart';

/// The job being applied to. A job that is closed or missing answers 404.
final applyJobProvider = FutureProvider.autoDispose.family<ApplyJob, String>(
  (ref, id) => ref.watch(applyRepositoryProvider).job(id),
  retry: (_, _) => null,
);

/// The applicant's CVs (`cv`) or cover letters (`cover_letter`).
final applyDocumentsProvider = FutureProvider.autoDispose
    .family<List<ApplyDocument>, String>(
      (ref, type) => ref.watch(applyRepositoryProvider).documents(type),
      retry: (_, _) => null,
    );

/// The applicant's certificate links, to tick on step 2.
final applyCertificatesProvider =
    FutureProvider.autoDispose<List<ApplyCertificate>>(
      (ref) => ref.watch(applyRepositoryProvider).certificates(),
      retry: (_, _) => null,
    );

/// What the applicant did before on a job. A failure counts as "nothing":
/// the API still refuses a second application, and the screen then says so.
final previousApplicationProvider = FutureProvider.autoDispose
    .family<PreviousApplication?, String>((ref, jobId) async {
      if (!ref.watch(authNotifierProvider).isAuthenticated) return null;
      try {
        return await ref.watch(applyRepositoryProvider).previous(jobId);
      } on Object {
        return null;
      }
    }, retry: (_, _) => null);

/// Counts the applications sent in this session. The app listens to it to
/// refresh the lists that show applications (`router.dart`), which keeps this
/// slice from reaching into the applications slice.
class ApplicationSubmittedNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void signal() => state++;
}

final applicationSubmittedProvider =
    NotifierProvider<ApplicationSubmittedNotifier, int>(
      ApplicationSubmittedNotifier.new,
    );

/// The page a failed request means, or null when it is only a message.
ApplyBlock? applyBlockOf(String? code) => switch (code) {
  ApplyConstants.codeEmailNotVerified => ApplyBlock.emailNotVerified,
  ApplyConstants.codeJobUnavailable => ApplyBlock.jobClosed,
  ApplyConstants.codeAlreadyApplied => ApplyBlock.alreadyApplied,
  ApplyConstants.codeApplyAgainNotAllowed => ApplyBlock.applyAgainNotAllowed,
  _ => null,
};

/// What the latest application of the applicant to the job means for a new
/// one: nothing (null), or the page that explains why none can be sent. A
/// closed application ("canApplyAgain") is the way back in.
ApplyBlock? applyBlockFor(PreviousApplication? previous) {
  if (previous == null || previous.canApplyAgain) return null;
  return ApplyConstants.closedStatuses.contains(previous.status)
      ? ApplyBlock.applyAgainNotAllowed
      : ApplyBlock.alreadyApplied;
}
