import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'documents_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpDocumentFonts();
  test('Documents font variants load from offline fixtures', () async {
    await GoogleFonts.pendingFonts();
    expect(GoogleFonts.config.httpClient, isNotNull);
  });
}
