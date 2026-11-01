import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/features/applicant/certificates/certificates_providers.dart';

import '../../helpers/fake_api.dart';

class _SwitchingAuth extends AuthNotifier {
  @override
  AuthState build() => AuthState.authenticated(userId: 'user-1');

  void loginAs(String id) => state = AuthState.authenticated(userId: id);

  @override
  Future<void> logout() async => state = AuthState.unauthenticated();
}

void main() {
  test('the Me badge count follows adds and deletes', () async {
    var total = 2;
    final adapter = FakeAdapter((options) {
      if (options.method == 'GET') {
        return jsonBody({
          'items': <dynamic>[],
          'page': 1,
          'totalPages': 1,
          'total': total,
          'suggestedTotal': 0,
        });
      }
      total += options.method == 'POST' ? 1 : -1;
      return jsonBody({
        'id': 'c1',
        'name': 'X',
        'url': 'https://x.example',
        'version': 1,
        'suggested': false,
        'sentCount': 0,
      });
    });
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(_SwitchingAuth.new),
        dioProvider.overrideWithValue(
          Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter,
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(certificateCountProvider, (_, _) {});
    addTearDown(sub.close);

    expect(await container.read(certificateCountProvider.future), 2);

    final actions = container.read(certificateActionsProvider);
    await actions.create(
      idempotencyKey: 'k',
      draft: const CertificateDraft(name: 'X', url: 'https://x.example'),
    );
    expect(await container.read(certificateCountProvider.future), 3);

    await actions.delete(
      const CertificateLink(
        id: 'c1',
        name: 'X',
        url: 'https://x.example',
        version: 1,
        suggested: false,
        sentCount: 0,
      ),
    );
    expect(await container.read(certificateCountProvider.future), 2);
  });

  test('Me badge count drops A count before loading B', () async {
    var total = 2;
    final adapter = FakeAdapter((options) => jsonBody({'total': total}));
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(_SwitchingAuth.new),
        dioProvider.overrideWithValue(
          Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter,
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(certificateCountProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(certificateCountProvider.future), 2);

    final auth =
        container.read(authNotifierProvider.notifier) as _SwitchingAuth;
    await auth.logout();
    expect(await container.read(certificateCountProvider.future), 0);
    total = 0;
    auth.loginAs('user-2');
    expect(await container.read(certificateCountProvider.future), 0);
  });
}
