import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cleancycle_mobileapp/main.dart';
import 'package:cleancycle_mobileapp/vishani/screens/tracking_dashboard_screen.dart';

void main() {
  testWidgets('CleanCycle App smoke test renders MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(TrackingDashboardScreen), findsOneWidget);
  });
}
