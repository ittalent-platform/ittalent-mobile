import 'dart:typed_data';
import 'dart:ui' as ui;

import '../profile_constants.dart';

enum AvatarFormat {
  jpeg('image/jpeg', 'jpg'),
  png('image/png', 'png'),
  webp('image/webp', 'webp');

  const AvatarFormat(this.mimeType, this.extension);

  final String mimeType;
  final String extension;
}

enum AvatarValidationError { unsupported, tooLarge, corrupt }

class ValidatedAvatarFile {
  const ValidatedAvatarFile({
    required this.bytes,
    required this.name,
    required this.format,
  });

  final Uint8List bytes;
  final String name;
  final AvatarFormat format;
}

class AvatarValidationException implements Exception {
  const AvatarValidationException(this.error, {this.byteLength});

  final AvatarValidationError error;
  final int? byteLength;
}

typedef AvatarDecoder = Future<void> Function(Uint8List bytes);

AvatarFormat? detectAvatarFormat(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return AvatarFormat.jpeg;
  }
  const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (bytes.length >= png.length &&
      List.generate(png.length, (index) => bytes[index]).join(',') ==
          png.join(',')) {
    return AvatarFormat.png;
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return AvatarFormat.webp;
  }
  return null;
}

Future<void> decodeAvatar(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  frame.image.dispose();
  codec.dispose();
}

Future<ValidatedAvatarFile> validateAvatarFile({
  required Uint8List bytes,
  required String name,
  AvatarDecoder decoder = decodeAvatar,
}) async {
  if (bytes.length > avatarMaxBytes) {
    throw AvatarValidationException(
      AvatarValidationError.tooLarge,
      byteLength: bytes.length,
    );
  }
  final format = detectAvatarFormat(bytes);
  if (format == null) {
    throw const AvatarValidationException(AvatarValidationError.unsupported);
  }
  try {
    await decoder(bytes);
  } catch (_) {
    throw const AvatarValidationException(AvatarValidationError.corrupt);
  }
  return ValidatedAvatarFile(bytes: bytes, name: name, format: format);
}

String avatarSizeLabel(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
