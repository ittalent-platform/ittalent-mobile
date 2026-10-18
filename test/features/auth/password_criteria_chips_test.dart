import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/auth/widgets/password_criteria_chips.dart';

void main() {
  group('PasswordCriteriaChips Static Validation', () {
    test('hasMinLength validates 8-64 characters', () {
      expect(PasswordCriteriaChips.hasMinLength('1234567'), isFalse);
      expect(PasswordCriteriaChips.hasMinLength('12345678'), isTrue);
      expect(PasswordCriteriaChips.hasMinLength('a' * 64), isTrue);
      expect(PasswordCriteriaChips.hasMinLength('a' * 65), isFalse);
    });

    test('hasUpper validates uppercase letters', () {
      expect(PasswordCriteriaChips.hasUpper('password'), isFalse);
      expect(PasswordCriteriaChips.hasUpper('Password'), isTrue);
    });

    test('hasLower validates lowercase letters', () {
      expect(PasswordCriteriaChips.hasLower('PASSWORD'), isFalse);
      expect(PasswordCriteriaChips.hasLower('passworD'), isTrue);
    });

    test('hasNumber validates numeric digits', () {
      expect(PasswordCriteriaChips.hasNumber('password'), isFalse);
      expect(PasswordCriteriaChips.hasNumber('password1'), isTrue);
    });

    test('hasSpecial validates special symbols', () {
      expect(PasswordCriteriaChips.hasSpecial('password123'), isFalse);
      expect(PasswordCriteriaChips.hasSpecial('password@123'), isTrue);
      expect(PasswordCriteriaChips.hasSpecial('pass#123'), isTrue);
    });

    test('allCriteriaMet requires all 5 rules', () {
      expect(PasswordCriteriaChips.allCriteriaMet('Secret1!'), isTrue);
      expect(PasswordCriteriaChips.allCriteriaMet('secret1!'), isFalse);
      expect(PasswordCriteriaChips.allCriteriaMet('Secret!!'), isFalse);
      expect(PasswordCriteriaChips.allCriteriaMet('Sec1!'), isFalse);
    });
  });

  group('PasswordCriteriaChips Widget', () {
    testWidgets('renders all 5 criteria labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PasswordCriteriaChips(password: '')),
        ),
      );

      expect(find.text('8–64 characters'), findsOneWidget);
      expect(find.text('An upper case letter'), findsOneWidget);
      expect(find.text('A lower case letter'), findsOneWidget);
      expect(find.text('A number'), findsOneWidget);
      expect(find.text('A special character'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('shows check icons for met criteria', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PasswordCriteriaChips(password: 'Hello2026')),
        ),
      );

      // 'Hello2026' satisfies min length (9 chars), upper, lower, number, but not special
      expect(find.byIcon(Icons.check), findsNWidgets(4));
    });

    testWidgets('shows 5 checks when all criteria are satisfied', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PasswordCriteriaChips(password: 'Hello2026!')),
        ),
      );

      expect(find.byIcon(Icons.check), findsNWidgets(5));
    });
  });
}
