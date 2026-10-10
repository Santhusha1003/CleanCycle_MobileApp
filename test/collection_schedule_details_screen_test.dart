import 'package:cleancycle_mobileapp/collection_schedule/models/collection_schedule.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/collection_schedule_details_screen.dart';
import 'package:cleancycle_mobileapp/collection_schedule/services/collection_schedule_reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReminderService implements CollectionScheduleReminderService {
  bool shouldFail;
  int calls = 0;

  _ReminderService({this.shouldFail = false});

  @override
  Future<void> scheduleReminder(CollectionSchedule schedule) async {
    calls++;
    if (shouldFail) throw StateError('permission unavailable');
  }
}

CollectionSchedule _schedule() => CollectionSchedule(
  id: 'actual-schedule-id',
  wasteType: 'Organic Waste',
  collectionDate: DateTime(2026, 10, 6),
  startTime: '08:00',
  endTime: '12:00',
  status: 'upcoming',
  acceptedItems: const ['Fruit and vegetable scraps'],
  instructions: 'Place the sealed bin by the gate.',
);

void main() {
  Future<void> pumpDetails(
    WidgetTester tester,
    CollectionScheduleReminderService reminders,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: CollectionScheduleDetailsScreen(
          schedule: _schedule(),
          reminderService: reminders,
        ),
      ),
    );
  }

  testWidgets('shows selected schedule data and category specific details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CollectionScheduleDetailsScreen(
          schedule: _schedule(),
          reminderService: _ReminderService(),
        ),
      ),
    );

    expect(find.text('Collection Details'), findsOneWidget);
    expect(find.text('Organic Waste'), findsOneWidget);
    expect(find.text('Tuesday, 6 October 2026'), findsOneWidget);
    expect(find.text('8:00 AM - 12:00 PM'), findsOneWidget);
    expect(find.text('UPCOMING'), findsOneWidget);
    expect(find.text('Fruit and vegetable scraps'), findsOneWidget);
    expect(find.text('Place the sealed bin by the gate.'), findsOneWidget);
    expect(find.byIcon(Icons.compost_outlined), findsOneWidget);
  });

  testWidgets('shows success only after reminder service completes', (
    tester,
  ) async {
    final reminders = _ReminderService();
    await pumpDetails(tester, reminders);
    await tester.ensureVisible(find.text('Set Reminder'));
    await tester.tap(find.text('Set Reminder'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(reminders.calls, 1);
    expect(find.text('Reminder scheduled for Organic Waste.'), findsOneWidget);
  });

  testWidgets('reports reminder scheduling failure without false success', (
    tester,
  ) async {
    final reminders = _ReminderService(shouldFail: true);
    await pumpDetails(tester, reminders);
    await tester.ensureVisible(find.text('Set Reminder'));
    await tester.tap(find.text('Set Reminder'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Could not set reminder'), findsOneWidget);
    expect(find.textContaining('Reminder scheduled'), findsNothing);
  });
}
