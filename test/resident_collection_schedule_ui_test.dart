import 'dart:async';

import 'package:cleancycle_mobileapp/collection_schedule/models/collection_schedule.dart';
import 'package:cleancycle_mobileapp/collection_schedule/services/collection_schedule_service.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/collection_schedule_screen.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/collection_schedule_details_screen.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/collection_calendar_screen.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/waste_categories_screen.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/recycling_tips_screen.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/collection_history_screen.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/missed_collection_report_screen.dart';
import 'package:cleancycle_mobileapp/collection_schedule/widgets/collection_bottom_nav.dart';
import 'package:cleancycle_mobileapp/widgets/common/app_card.dart';
import 'package:cleancycle_mobileapp/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Schedules implements CollectionScheduleService {
  _Schedules(List<CollectionSchedule> records) : stream = Stream.value(records);
  _Schedules.stream(this.stream);
  final Stream<List<CollectionSchedule>> stream;
  @override
  Stream<List<CollectionSchedule>> getSchedules() => stream;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected mutation');
}

class _Routes extends NavigatorObserver {
  Route<dynamic>? last;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    last = route;
  }
}

CollectionSchedule _schedule(
  DateTime date,
  String waste, {
  String status = 'scheduled',
  String time = '08:00',
}) => CollectionSchedule(
  id: waste,
  wasteType: waste,
  collectionDate: date,
  startTime: time,
  endTime: time.isEmpty ? '' : '10:00',
  status: status,
  acceptedItems: [],
  instructions: '',
);

Future<void> _open(
  WidgetTester tester,
  _Schedules service, {
  double width = 430,
  double scale = 1,
  _Routes? observer,
  bool settle = true,
}) async {
  tester.view.physicalSize = Size(width, 850);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: observer == null ? [] : [observer],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: CollectionScheduleScreen(scheduleService: service),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Finder _card(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(AppCard)).first;

void main() {
  testWidgets(
    'Calendar loads the shared Resident projection for its selected date',
    (tester) async {
      final date = DateTime.now();
      final schedule = _schedule(
        date,
        'Resident projection schedule',
        status: 'scheduled',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CollectionCalendarScreen(
            scheduleService: _Schedules([schedule]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Select a date to view collection schedules.'),
        findsOneWidget,
      );
      await tester.tap(find.text('${date.day}'));
      await tester.pumpAndSettle();
      expect(find.text('Resident projection schedule'), findsOneWidget);
    },
  );

  testWidgets(
    'Week/month control preserves filtering, sorting and selected semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final otherMonthDay =
          List.generate(
            DateTime(now.year, now.month + 1, 0).day,
            (index) => DateTime(now.year, now.month, index + 1),
          ).firstWhere(
            (date) =>
                date.isBefore(weekStart) ||
                !date.isBefore(weekStart.add(const Duration(days: 7))),
          );
      await _open(
        tester,
        _Schedules([
          _schedule(today, 'Weekly record'),
          _schedule(otherMonthDay, 'Monthly record'),
          _schedule(DateTime(now.year, now.month - 1, 1), 'Outside month'),
        ]),
      );
      expect(find.text('Weekly record'), findsOneWidget);
      expect(find.text('Monthly record'), findsNothing);
      expect(
        tester.getSemantics(find.text('This Week')),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isFocusable: true,
          hasFocusAction: true,
          hasTapAction: true,
          label: 'This Week',
        ),
      );
      await tester.tap(find.text('This Month'));
      await tester.pumpAndSettle();
      expect(find.text('Monthly record'), findsOneWidget);
      expect(find.text('Outside month'), findsNothing);
      expect(
        tester.getSemantics(find.text('This Month')),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isFocusable: true,
          hasFocusAction: true,
          hasTapAction: true,
          label: 'This Month',
        ),
      );
      final sorted = [today, otherMonthDay]..sort();
      final firstText = sorted.first == today
          ? 'Weekly record'
          : 'Monthly record';
      expect(
        tester.getTopLeft(find.text(firstText)).dy,
        lessThan(
          tester
              .getTopLeft(
                find.text(
                  firstText == 'Weekly record'
                      ? 'Monthly record'
                      : 'Weekly record',
                ),
              )
              .dy,
        ),
      );
      semantics.dispose();
    },
  );

  for (final width in [320.0, 430.0]) {
    testWidgets(
      'Long schedule text fits $width at larger text size and scrolls above navigation',
      (tester) async {
        await _open(
          tester,
          _Schedules([
            _schedule(
              DateTime.now(),
              'Recyclable waste with a very long category description for this collection',
              status: 'A long status label provided by the stored record',
            ),
          ]),
          width: width,
          scale: 1.4,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.text(
            'Recyclable waste with a very long category description for this collection',
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('08:00 – 10:00'), findsOneWidget);
        expect(
          find.text('A long status label provided by the stored record'),
          findsOneWidget,
        );
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -700),
        );
        await tester.pumpAndSettle();
        final nav = find.byType(CollectionBottomNav);
        expect(
          tester
              .getBottomLeft(
                _card(
                  'Recyclable waste with a very long category description for this collection',
                ),
              )
              .dy,
          lessThanOrEqualTo(tester.getTopLeft(nav).dy),
        );
        expect(tester.widget<CollectionBottomNav>(nav).currentIndex, 1);
      },
    );
  }

  testWidgets(
    'Information card styling and all existing destinations are preserved',
    (tester) async {
      final observer = _Routes();
      await _open(tester, _Schedules([]), observer: observer);
      final cases = <(String, Type, Color)>[
        ('Waste Categories', WasteCategoriesScreen, AppColors.greenSurface),
        ('Recycling Guide', RecyclingTipsScreen, AppColors.greenSurface),
        ('Collection History', CollectionHistoryScreen, Colors.white),
        (
          'Report Missed Collection',
          MissedCollectionReportScreen,
          const Color(0xFFFFF8E1),
        ),
      ];
      final context = tester.element(find.byType(CollectionScheduleScreen));
      for (final entry in cases) {
        final card = tester.widget<AppCard>(_card(entry.$1));
        expect(card.color, entry.$3);
        expect(card.showBorder, isTrue);
        expect(card.elevation, 0);
        card.onTap!();
        final route = observer.last! as MaterialPageRoute<dynamic>;
        // Inspect the actual destination builder without initializing unrelated
        // Firestore screens. Their implementations are outside this UI change.
        expect(route.buildContent(context).runtimeType, entry.$2);
        Navigator.of(context).removeRoute(route);
        await tester.pumpAndSettle();
      }
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.calendar_month_outlined),
          )
          .onPressed!();
      final calendar = observer.last! as MaterialPageRoute<dynamic>;
      expect(calendar.buildContent(context), isA<CollectionCalendarScreen>());
      Navigator.of(context).removeRoute(calendar);
      await tester.pumpAndSettle();
      expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
    },
  );

  testWidgets(
    'Entire collection card opens existing details for the actual record',
    (tester) async {
      final record = _schedule(DateTime.now(), 'organic');
      await _open(tester, _Schedules([record]));
      await tester.ensureVisible(_card('organic'));
      await tester.tap(_card('organic'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CollectionScheduleDetailsScreen>(
              find.byType(CollectionScheduleDetailsScreen),
            )
            .schedule,
        same(record),
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CollectionScheduleScreen), findsOneWidget);
    },
  );

  testWidgets('Missing optional time/status are omitted without placeholders', (
    tester,
  ) async {
    await _open(
      tester,
      _Schedules([_schedule(DateTime.now(), 'general', time: '', status: '')]),
    );
    final card = _card('general');
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.schedule_outlined)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.byIcon(Icons.check_circle_outline),
      ),
      findsNothing,
    );
    expect(find.text('Not available'), findsNothing);
  });

  testWidgets(
    'Loading, error and empty states retain usable navigation cards',
    (tester) async {
      final controller = StreamController<List<CollectionSchedule>>();
      addTearDown(controller.close);
      await _open(tester, _Schedules.stream(controller.stream), settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      controller.addError(Exception('permission-denied'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Error loading schedules:'), findsOneWidget);
      expect(find.text('Report Missed Collection'), findsOneWidget);
      controller.add([]);
      await tester.pumpAndSettle();
      expect(find.text('No collection schedules available.'), findsOneWidget);
    },
  );
}
