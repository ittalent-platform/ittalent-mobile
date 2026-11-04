import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/routes.dart';

/// Where a guest who goes to sign in is brought back to afterwards: the job
/// they were reading, or the apply page they were sent away from. The router
/// takes it when the sign-in succeeds (see `RouterNotifier`).
class SignInReturnNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Keeps [location] if it is a place [AppRoutes.returnTarget] accepts.
  void remember(String? location) => state = AppRoutes.returnTarget(location);

  void forget() => state = null;

  /// The place to go back to, once; null when there is none.
  String? take() {
    final location = state;
    state = null;
    return location;
  }
}

final signInReturnProvider = NotifierProvider<SignInReturnNotifier, String?>(
  SignInReturnNotifier.new,
);

/// Sends a guest to sign in, and back to [location] once they have.
///
/// The router cannot read this from the login page: its redirect only sees the
/// location under the pages that were pushed (a guest who browsed from the
/// welcome page is "on" the welcome page, whatever is above it), so the place
/// is kept in [signInReturnProvider] as well as in the `from` of the login
/// address.
Future<void> signInThen(
  BuildContext context,
  WidgetRef ref,
  String location,
) async {
  final signInReturn = ref.read(signInReturnProvider.notifier)
    ..remember(location);
  final login = AppRoutes.loginThen(location);
  if (!context.canPop()) {
    // Nothing is under this page (a link opened it): the login page replaces
    // it, and is then the location the router sees.
    context.go(login);
    return;
  }
  await context.push<void>(login);
  // Back from the login page without signing in: a later sign-in, from
  // anywhere, must not jump to this place.
  signInReturn.forget();
}
