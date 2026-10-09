import 'package:cleancycle_mobileapp/app.dart';
import 'package:cleancycle_mobileapp/core/constants/app_roles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CleanCycleApp(firebaseReady: false));
    await tester.pump(const Duration(seconds: 7));
    await tester.pump();
  }

  testWidgets('Login CTA stays disabled until email and password are filled', (
    tester,
  ) async {
    await pumpLogin(tester);

    ElevatedButton loginButton() {
      return tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'LOGIN'),
      );
    }

    expect(loginButton().onPressed, isNull);

    await tester.enterText(find.byType(TextFormField).at(0), 'not-valid');
    await tester.pump();
    expect(loginButton().onPressed, isNull);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'resident@cleancycle.app',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.pump();
    expect(loginButton().onPressed, isNotNull);
  });

  testWidgets('Sign Up opens Create Account', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Create Your Account'), findsOneWidget);
    expect(find.text('SELECT ROLE'), findsOneWidget);
    final selector = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(selector.items!.map((item) => item.value), AppRoles.all);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Driver').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('requires approval'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Municipal Officer').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('requires approval'), findsOneWidget);
  });

  testWidgets('Forgot Password opens the reset-email screen', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot Password'), findsWidgets);
    expect(find.text('Send Reset Link'), findsOneWidget);
  });
}
