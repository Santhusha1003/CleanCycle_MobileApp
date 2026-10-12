import 'package:cleancycle_mobileapp/screens/municipal_dashboard_screen.dart';
import 'package:cleancycle_mobileapp/services/firebase/firestore_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/municipal_analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/tracking_firestore.dart';

void main() {
  late TrackingFirestoreFixture db;
  late DateTime now;

  setUp(() {
    db = TrackingFirestoreFixture()..documents.clear();
    now = DateTime.utc(2026, 10, 13, 8);
  });
  tearDown(() => db.dispose());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MunicipalDashboardScreen(
          analyticsService: MunicipalAnalyticsService(
            firestoreService: FirestoreService(firestoreInstance: db),
            now: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('total, labels and chart share live today records', (
    tester,
  ) async {
    for (final status in [
      'completed',
      'In Progress',
      'missed',
      'scheduled',
      'cancelled',
    ]) {
      db.documents['schedules/$status'] = {
        'collectionDate': '2026-10-13',
        'status': status,
      };
    }
    db.documents['schedules/old'] = {
      'collectionDate': '2026-10-12',
      'status': 'completed',
    };
    await open(tester);
    expect(find.text('5 routes'), findsOneWidget);
    expect(
      find.byTooltip('Scheduled: 1\nCancelled: 1\nUnknown status: 0'),
      findsOneWidget,
    );
    for (final label in ['Completed', 'In Progress', 'Missed']) {
      final row = find
          .ancestor(of: find.text(label), matching: find.byType(Row))
          .first;
      expect(
        find.descendant(of: row, matching: find.text('1')),
        findsOneWidget,
      );
    }
    final chart = find
        .ancestor(of: find.text('Total'), matching: find.byType(CustomPaint))
        .first;
    final dynamic painter = tester.widget<CustomPaint>(chart).painter;
    expect(painter.total, 5);
    expect(painter.completed, 1);
    expect(painter.inProgress, 1);
    expect(painter.missed, 1);
    db.documents['schedules/scheduled']!['status'] = 'completed';
    db.publish();
    await tester.pumpAndSettle();
    final dynamic updated = tester.widget<CustomPaint>(chart).painter;
    expect(updated.total, 5);
    expect(updated.completed, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('empty state and Colombo midnight refresh without a write', (
    tester,
  ) async {
    now = DateTime.utc(2026, 10, 13, 18, 29);
    db.documents['schedules/today'] = {
      'collectionDate': '2026-10-13',
      'status': 'completed',
    };
    await open(tester);
    expect(find.text('1 routes'), findsOneWidget);
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('No routes'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('denied reads show error and retry resubscribes safely', (
    tester,
  ) async {
    db.denied.add('schedules');
    await open(tester);
    expect(find.text('Unable to load dashboard'), findsOneWidget);
    expect(find.text('No routes'), findsNothing);
    db.denied.clear();
    await tester.tap(find.text('Retry'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('No routes'), findsOneWidget);
    expect(find.text('Unable to load dashboard'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
