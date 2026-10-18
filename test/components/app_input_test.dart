import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/components/ui/app_input.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  testWidgets('AppInput renders with label, hint, and text input', (
    WidgetTester tester,
  ) async {
    String changedValue = '';
    final controller = TextEditingController();

    await tester.pumpWidget(
      buildTestableWidget(
        AppInput(
          controller: controller,
          label: 'Email',
          hintText: 'user@example.com',
          onChanged: (v) => changedValue = v,
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'test@domain.com');
    expect(changedValue, 'test@domain.com');
    expect(controller.text, 'test@domain.com');
  });

  testWidgets('AppInput renders with labelTrailing widget', (
    WidgetTester tester,
  ) async {
    bool forgotPasswordTapped = false;

    await tester.pumpWidget(
      buildTestableWidget(
        AppInput(
          label: 'Password',
          labelTrailing: GestureDetector(
            onTap: () => forgotPasswordTapped = true,
            child: const Text('Forgot password?'),
          ),
        ),
      ),
    );

    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    expect(forgotPasswordTapped, isTrue);
  });

  testWidgets('AppInput renders errorText and prefix/suffix icons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const AppInput(
          label: 'Account',
          errorText: 'Required field',
          prefixIcon: Icon(Icons.person, key: Key('prefix-icon')),
          suffixIcon: Icon(Icons.visibility, key: Key('suffix-icon')),
        ),
      ),
    );

    expect(find.text('Required field'), findsOneWidget);
    expect(find.byKey(const Key('prefix-icon')), findsOneWidget);
    expect(find.byKey(const Key('suffix-icon')), findsOneWidget);
  });
}
