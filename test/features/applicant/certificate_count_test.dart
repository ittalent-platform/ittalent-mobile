import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/features/applicant/certificates/certificates_providers.dart';

import '../../helpers/fake_api.dart';

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
}
