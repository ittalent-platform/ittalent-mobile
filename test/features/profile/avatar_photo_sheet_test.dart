import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ittalent_mobile/features/profile/profile_providers.dart';
import 'package:ittalent_mobile/features/profile/widgets/avatar_photo_sheet.dart';

import 'profile_test_support.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

Future<void> pumpSheet(
  WidgetTester tester,
  FakeProfileRepository repository,
  List<XFile> picks,
) async {
  var index = 0;
  await tester.pumpWidget(
    localizedApp(
      home: Scaffold(body: AvatarPhotoSheet(profile: repository.profile)),
      overrides: [
        profileRepositoryProvider.overrideWithValue(repository),
        avatarPickerProvider.overrideWithValue((_) async => picks[index++]),
        avatarDecoderProvider.overrideWithValue((_) async {}),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeProfileTests();
  });

  testWidgets('null MIME GIF is rejected before decoding', (tester) async {
    final gif = XFile.fromData(
      Uint8List.fromList('GIF89a'.codeUnits),
      name: 'avatar.gif',
      mimeType: null,
    );
    await pumpSheet(tester, FakeProfileRepository(testProfile()), [gif]);
    await tester.tap(find.byKey(const Key('avatar_library')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('avatar_error')), findsOneWidget);
    expect(find.textContaining('GIF, SVG'), findsOneWidget);
    expect(find.byKey(const Key('avatar_save')), findsNothing);
  });

  testWidgets('invalid second pick clears stale preview and Save photo', (
    tester,
  ) async {
    final valid = XFile.fromData(
      _png,
      name: 'avatar.png',
      mimeType: 'image/png',
    );
    final renamedGif = XFile.fromData(
      Uint8List.fromList('GIF89a'.codeUnits),
      name: 'avatar.jpg',
      mimeType: 'image/jpeg',
    );
    await pumpSheet(tester, FakeProfileRepository(testProfile()), [
      valid,
      renamedGif,
    ]);

    await tester.tap(find.byKey(const Key('avatar_library')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('avatar_preview')), findsOneWidget);
    expect(find.byKey(const Key('avatar_save')), findsOneWidget);

    await tester.tap(find.byKey(const Key('avatar_library')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('avatar_preview')), findsNothing);
    expect(find.byKey(const Key('avatar_save')), findsNothing);
    expect(find.byKey(const Key('avatar_error')), findsOneWidget);
  });

  testWidgets('helper describes formats, limit and current-photo behavior', (
    tester,
  ) async {
    await pumpSheet(tester, FakeProfileRepository(testProfile()), [
      XFile.fromData(_png, name: 'avatar.png'),
    ]);
    expect(
      find.text(
        'JPG, PNG or WebP, up to 5 MB. Your current photo stays until you save a new one.',
      ),
      findsOneWidget,
    );
  });
}
