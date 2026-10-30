import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/components/ui/app_button.dart';
import 'package:ittalent_mobile/features/profile/edit_profile_screen.dart';
import 'package:ittalent_mobile/features/profile/profile_providers.dart';

import 'profile_test_support.dart';

Finder field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

Future<FakeProfileRepository> pumpEdit(WidgetTester tester) async {
  final repository = FakeProfileRepository(testProfile());
  await tester.pumpWidget(
    localizedApp(
      home: const EditProfileScreen(),
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeProfileTests();
  });

  testWidgets('invalid errors clear and Save enables after correcting input', (
    tester,
  ) async {
    await pumpEdit(tester);
    await tester.enterText(field(const Key('profile_name')), 'A');
    await tester.enterText(field(const Key('profile_phone')), '123');
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('profile_save')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(
      find.text('Enter a name between 2 and 100 characters.'),
      findsOneWidget,
    );
    expect(
      find.text('Enter a valid Vietnamese mobile number.'),
      findsOneWidget,
    );
    expect(
      tester.widget<AppButton>(find.byKey(const Key('profile_save'))).onPressed,
      isNull,
    );

    await tester.enterText(field(const Key('profile_name')), 'Nguyen Van B');
    await tester.enterText(field(const Key('profile_phone')), '0987654321');
    await tester.pump();
    expect(find.textContaining('between 2 and 100'), findsNothing);
    expect(find.textContaining('valid Vietnamese'), findsNothing);
    expect(
      tester.widget<AppButton>(find.byKey(const Key('profile_save'))).onPressed,
      isNotNull,
    );
  });

  testWidgets('no-change form never calls update API', (tester) async {
    final repository = await pumpEdit(tester);
    expect(
      tester.widget<AppButton>(find.byKey(const Key('profile_save'))).onPressed,
      isNull,
    );
    await tester.tap(
      find.byKey(const Key('profile_save')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(repository.updateCalls, 0);
  });

  testWidgets('network error keeps typed values and shows retry callout', (
    tester,
  ) async {
    (await pumpEdit(tester)).updateError = const ApiError(message: 'offline');
    await tester.enterText(field(const Key('profile_name')), 'Kept Name');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_update_error')), findsOneWidget);
    expect(find.text('Kept Name'), findsOneWidget);
    expect(find.byKey(const Key('profile_update_retry')), findsOneWidget);
  });

  testWidgets('409 supports Cancel and Load latest without raw keys', (
    tester,
  ) async {
    final repository = await pumpEdit(tester)
      ..updateError = const ApiError(message: 'conflict', statusCode: 409);
    await tester.enterText(field(const Key('profile_name')), 'Changed Name');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile_save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Profile was updated'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('common.cancel'), findsNothing);
    await tester.tap(find.byKey(const Key('profile_conflict_cancel')));
    await tester.pumpAndSettle();
    expect(find.text('Changed Name'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile_save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    repository
      ..profile = testProfile(fullName: 'Latest Name', version: 4)
      ..updateError = null;
    await tester.tap(find.byKey(const Key('profile_conflict_load')));
    await tester.pumpAndSettle();
    expect(find.text('Latest Name'), findsOneWidget);
    expect(repository.getCalls, 2);
  });
}
