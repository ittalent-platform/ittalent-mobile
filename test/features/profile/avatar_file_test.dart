import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/profile/profile_constants.dart';
import 'package:ittalent_mobile/features/profile/widgets/avatar_file.dart';

Future<void> accepts(Uint8List _) async {}

void main() {
  final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0xdb]);
  final png = Uint8List.fromList([
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
  ]);
  final webp = Uint8List.fromList([
    ...'RIFF'.codeUnits,
    0,
    0,
    0,
    0,
    ...'WEBP'.codeUnits,
  ]);

  test('detects JPEG, PNG and WebP from bytes, not extension', () async {
    expect(
      (await validateAvatarFile(
        bytes: jpeg,
        name: 'photo.unknown',
        decoder: accepts,
      )).format,
      AvatarFormat.jpeg,
    );
    expect(
      (await validateAvatarFile(
        bytes: png,
        name: 'photo.gif',
        decoder: accepts,
      )).format,
      AvatarFormat.png,
    );
    expect(
      (await validateAvatarFile(
        bytes: webp,
        name: 'photo',
        decoder: accepts,
      )).format,
      AvatarFormat.webp,
    );
  });

  test('rejects GIF, SVG, unknown bytes and GIF renamed to jpg', () async {
    final cases = [
      ('photo.gif', Uint8List.fromList('GIF89a'.codeUnits)),
      ('photo.svg', Uint8List.fromList('<svg/>'.codeUnits)),
      ('photo.bin', Uint8List.fromList([1, 2, 3, 4])),
      ('photo.jpg', Uint8List.fromList('GIF89a'.codeUnits)),
    ];
    for (final item in cases) {
      expect(
        () =>
            validateAvatarFile(bytes: item.$2, name: item.$1, decoder: accepts),
        throwsA(
          isA<AvatarValidationException>().having(
            (error) => error.error,
            'error',
            AvatarValidationError.unsupported,
          ),
        ),
      );
    }
  });

  test('rejects a file over 5 MiB and reports its real size', () async {
    final bytes = Uint8List(avatarMaxBytes + 1)..setRange(0, jpeg.length, jpeg);
    expect(
      () =>
          validateAvatarFile(bytes: bytes, name: 'large.jpg', decoder: accepts),
      throwsA(
        isA<AvatarValidationException>()
            .having(
              (error) => error.error,
              'error',
              AvatarValidationError.tooLarge,
            )
            .having(
              (error) => error.byteLength,
              'byteLength',
              avatarMaxBytes + 1,
            ),
      ),
    );
  });

  test('rejects a supported signature when image decoding fails', () async {
    expect(
      () => validateAvatarFile(
        bytes: jpeg,
        name: 'broken.jpg',
        decoder: (_) async => throw const FormatException(),
      ),
      throwsA(
        isA<AvatarValidationException>().having(
          (error) => error.error,
          'error',
          AvatarValidationError.corrupt,
        ),
      ),
    );
  });
}
