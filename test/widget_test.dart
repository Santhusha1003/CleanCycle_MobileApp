import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cleancycle_mobileapp/app.dart';

void main() {
  testWidgets('Login screen shows branding and login CTA', (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CleanCycleApp(firebaseReady: false));

    expect(find.text('CleanCycle'), findsOneWidget);
    expect(find.text('Clean Today, Greener Tomorrow'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Login as Driver'), findsNothing);
    expect(find.text('Login as Municipal Officer'), findsNothing);
  });
}
