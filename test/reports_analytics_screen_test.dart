import 'dart:async';
import 'package:cleancycle_mobileapp/widgets/municipal/performance_charts.dart';

import 'package:cleancycle_mobileapp/screens/reports_analytics_screen.dart';
import 'package:cleancycle_mobileapp/services/municipal/municipal_analytics_service.dart';
import 'package:cleancycle_mobileapp/widgets/common/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MunicipalAnalyticsSummary _summary({bool empty = false}) =>
    MunicipalAnalyticsSummary(
      completedCollectionsByVehicleToday: empty ? {} : {'REAL-ID-1': 3},
      totalVehicles: empty ? 0 : 12,
      availableVehicles: empty ? 0 : 8,
      maintenanceVehicles: empty ? 0 : 2,
      totalDrivers: empty ? 0 : 14,
      availableDrivers: empty ? 0 : 9,
      assignedDrivers: empty ? 0 : 3,
      totalStaff: empty ? 0 : 16,
      activeStaff: empty ? 0 : 11,
      todayCollections: empty ? 0 : 20,
      completedToday: empty ? 0 : 8,
      scheduledToday: empty ? 0 : 7,
      inProgressToday: empty ? 0 : 3,
      cancelledToday: empty ? 0 : 2,
      collectionsByWasteType: empty ? {} : {'general': 13, 'recyclable': 7},
      collectionsByZone: empty
          ? {}
          : {'A very long municipal collection zone name': 20},
    );

// Test data stays in memory; this UI test never calls Firebase.
class _Analytics implements MunicipalAnalyticsService {
  MunicipalAnalyticsSummary summary = _summary();
  Exception? error;
  Completer<MunicipalAnalyticsSummary>? pending;
  int calls = 0;
  @override
  Future<MunicipalAnalyticsSummary> getMunicipalAnalyticsSummary() async {
    calls++;
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
    return summary;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester,
  _Analytics service, {
  double width = 430,
  double scale = 1,
  bool settle = true,
}) async {
  tester.view.physicalSize = Size(width, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: ReportsAnalyticsScreen(analyticsService: service),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Finder _card(String heading) =>
    find.ancestor(of: find.text(heading), matching: find.byType(AppCard));

void main() {
  testWidgets(
    'Reports maps vehicle counts and leaves unrecorded driver routes empty',
    (tester) async {
      await _open(tester, _Analytics());
      expect(
        tester
            .widget<VehiclePerformanceChart>(
              find.byType(VehiclePerformanceChart),
            )
            .collections,
        {'REAL-ID-1': 3},
      );
      expect(
        tester
            .widget<DriverPerformanceChart>(find.byType(DriverPerformanceChart))
            .completedRoutes,
        isEmpty,
      );
      await tester.ensureVisible(find.text('Vehicle Performance'));
      await tester.pumpAndSettle();
      expect(find.text('REAL-ID-1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Header and daily collection performance use actual supplied values',
    (tester) async {
      await _open(tester, _Analytics());
      expect(find.text('CleanCycle'), findsOneWidget);
      expect(find.text('Collection Analytics'), findsOneWidget);
      expect(
        find.text('Overview of municipal collection performance.'),
        findsOneWidget,
      );
      expect(find.textContaining('Today ·'), findsOneWidget);
      expect(find.byType(DateRangePickerDialog), findsNothing);
      final section = _card('Collection Performance');
      expect(
        find.descendant(of: section, matching: find.text('20')),
        findsOneWidget,
      );
      final bars = tester
          .widgetList<LinearProgressIndicator>(
            find.descendant(
              of: section,
              matching: find.byType(LinearProgressIndicator),
            ),
          )
          .toList();
      expect(bars.map((bar) => bar.value), [8 / 20, 3 / 20, 7 / 20, 2 / 20]);
    },
  );

  testWidgets('Every KPI shows the matching summary value', (tester) async {
    await _open(tester, _Analytics());
    const metrics = {
      'Total Vehicles': 12,
      'Available Vehicles': 8,
      'Total Drivers': 14,
      'Available Drivers': 9,
      'Total Staff': 16,
      'Active Staff': 11,
      "Today's Collections": 20,
      'Completed': 8,
      'In Progress': 3,
      'Cancelled': 2,
    };
    for (final entry in metrics.entries) {
      final matchingCards = tester.widgetList<AppCard>(_card(entry.key));
      // Status labels also appear inside their section; select the compact KPI.
      final metric = matchingCards.last;
      final card = find.byWidget(metric);
      expect(
        find.descendant(of: card, matching: find.text('${entry.value}')),
        findsOneWidget,
      );
    }
  });

  for (final width in [320.0, 430.0]) {
    testWidgets(
      'Aggregate sections and breakdowns fit width $width with larger text',
      (tester) async {
        await _open(tester, _Analytics(), width: width, scale: 1.3);
        for (final heading in [
          'Vehicle Status',
          'Driver Overview',
          'Staff Overview',
          'Collections by Waste Type',
          'Collections by Zone',
        ]) {
          await tester.scrollUntilVisible(
            find.text(heading),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text(heading), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        expect(
          find.text('A very long municipal collection zone name'),
          findsOneWidget,
        );
        expect(find.text('Assigned'), findsOneWidget);
        expect(find.text('In Maintenance'), findsOneWidget);
      },
    );
  }

  testWidgets('Zero summaries have empty messages and finite progress values', (
    tester,
  ) async {
    await _open(tester, _Analytics()..summary = _summary(empty: true));
    expect(find.text('No collections scheduled for today.'), findsOneWidget);
    for (final message in [
      'No vehicles recorded.',
      'No drivers recorded.',
      'No staff recorded.',
      'No collections today by waste type.',
      'No collections today by zone.',
    ]) {
      await tester.scrollUntilVisible(
        find.text(message),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(message), findsOneWidget);
    }
    for (final bar in tester.widgetList<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    )) {
      expect(bar.value, 0);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Loading, errors and Retry remain functional', (tester) async {
    final service = _Analytics()
      ..pending = Completer<MunicipalAnalyticsSummary>();
    await _open(tester, service, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    service.pending!.completeError(Exception('Test analytics unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load analytics'), findsOneWidget);
    service.pending = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Collection Performance'), findsOneWidget);
    expect(service.calls, 2);
  });

  testWidgets('Toolbar refresh and pull-to-refresh reload existing analytics', (
    tester,
  ) async {
    final service = _Analytics();
    await _open(tester, service);
    service.summary = _summary(empty: true);
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(service.calls, 2);
    expect(find.text('No collections scheduled for today.'), findsOneWidget);
    service.summary = _summary();
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(service.calls, 3);
    expect(find.text('No collections scheduled for today.'), findsNothing);
  });
}
