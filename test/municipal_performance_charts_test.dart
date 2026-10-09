import 'package:cleancycle_mobileapp/widgets/municipal/performance_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(
  WidgetTester tester,
  Widget chart, {
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 1000);
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
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: chart,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Vehicle bars show actual counts, baseline, scale and active count',
    (tester) async {
      await _show(
        tester,
        const VehiclePerformanceChart(collections: {'V-B': 2, 'V-A': 4}),
      );
      expect(find.text('Vehicle Performance'), findsOneWidget);
      expect(find.text('Trips / Day'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      final high = find.byKey(const ValueKey('vehicle-bar-V-A'));
      final low = find.byKey(const ValueKey('vehicle-bar-V-B'));
      expect(tester.getSize(high).height, 126);
      expect(tester.getSize(low).height, 63);
      expect(tester.getBottomLeft(high).dy, tester.getBottomLeft(low).dy);
      expect(tester.getTopLeft(high).dx, lessThan(tester.getTopLeft(low).dx));
      expect(
        find.text('Scale: 0–4 collections/day · Active vehicles in chart: 2'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Driver counts are descending with stable ties and proportional bars',
    (tester) async {
      await _show(
        tester,
        const DriverPerformanceChart(
          completedRoutes: {
            'Low': 1,
            'Zed': 3,
            'Amy': 3,
            ' ': 10,
            'Zero': 0,
            'Invalid': -1,
          },
        ),
      );
      final bars = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .toList();
      expect(bars.map((bar) => bar.key), [
        const ValueKey('driver-bar-Amy'),
        const ValueKey('driver-bar-Zed'),
        const ValueKey('driver-bar-Low'),
      ]);
      expect(bars.map((bar) => bar.value), [1.0, 1.0, 1 / 3]);
      expect(find.text('Zero'), findsNothing);
      expect(find.text('Invalid'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Missing performance history shows explicit empty states without bars',
    (tester) async {
      await _show(
        tester,
        const Column(
          children: [
            VehiclePerformanceChart(collections: {}),
            DriverPerformanceChart(),
          ],
        ),
      );
      expect(find.textContaining('No completed collections'), findsOneWidget);
      expect(
        find.textContaining('Completed-route history is not recorded'),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('Scale:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Many vehicle labels scroll and long driver names fit large text',
    (tester) async {
      await _show(
        tester,
        Column(
          children: [
            VehiclePerformanceChart(
              collections: {for (int i = 1; i <= 12; i++) 'REGISTRATION-$i': i},
            ),
            const DriverPerformanceChart(
              completedRoutes: {
                'A driver with a very long name': 100,
                'Another driver with a long name': 55,
              },
            ),
          ],
        ),
        scale: 1.5,
      );
      final horizontal = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      );
      expect(horizontal, findsOneWidget);
      await tester.drag(horizontal, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
