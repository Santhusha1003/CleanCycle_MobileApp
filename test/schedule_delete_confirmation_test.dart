import 'package:cleancycle_mobileapp/widgets/common/municipal_crud_actions.dart';
import 'dart:async';

import 'package:cleancycle_mobileapp/models/collection_schedule.dart';
import 'package:cleancycle_mobileapp/screens/schedule_management_screen.dart';
import 'package:cleancycle_mobileapp/services/municipal/schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// All records are local test fixtures; Firebase is never initialized or called.
class _Schedules implements ScheduleService {
  final records = <CollectionSchedule>[
    CollectionSchedule(
      scheduleId: 'confirmation-test',
      zone: 'Test zone',
      collectionDate: DateTime(2026, 10, 9),
      startTime: '08:00',
      endTime: '12:00',
      wasteType: 'general',
      status: 'scheduled',
      createdAt: null,
      updatedAt: null,
    ),
  ];
  final deletedIds = <String>[];
  Completer<void>? pendingDelete;
  Exception? deleteError;

  @override
  Future<List<CollectionSchedule>> getSchedules() async => List.of(records);

  @override
  Future<void> deleteSchedule({required String scheduleId}) async {
    deletedIds.add(scheduleId);
    if (deleteError != null) throw deleteError!;
    if (pendingDelete != null) await pendingDelete!.future;
    records.removeWhere((schedule) => schedule.scheduleId == scheduleId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _openScreen(WidgetTester tester, _Schedules service) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(home: ScheduleManagementScreen(scheduleService: service)),
  );
  await tester.pumpAndSettle();
  expect(find.byType(MunicipalCrudActions), findsOneWidget);
}

Finder _dialogButton(String text) => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.widgetWithText(OutlinedButton, text),
);

void main() {
  testWidgets('Delete opens confirmation; Cancel leaves the schedule untouched', (
    tester,
  ) async {
    final service = _Schedules();
    await _openScreen(tester, service);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Schedule?'), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to delete this collection schedule? This action cannot be undone.',
      ),
      findsOneWidget,
    );
    expect(service.deletedIds, isEmpty);
    await tester.tap(_dialogButton('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(service.deletedIds, isEmpty);
    expect(find.text('Test zone'), findsOneWidget);
  });

  testWidgets('Dismissing confirmation does not delete', (tester) async {
    final service = _Schedules();
    await _openScreen(tester, service);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(service.deletedIds, isEmpty);
  });

  testWidgets('Confirm calls existing delete once and shows success', (
    tester,
  ) async {
    final service = _Schedules();
    await _openScreen(tester, service);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(_dialogButton('Delete'));
    await tester.pumpAndSettle();
    expect(service.deletedIds, ['confirmation-test']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Schedule deleted successfully.'), findsOneWidget);
    expect(find.text('Test zone'), findsNothing);
  });

  testWidgets(
    'Repeated taps cannot queue dialogs or duplicate an in-flight delete',
    (tester) async {
      final service = _Schedules()..pendingDelete = Completer<void>();
      await _openScreen(tester, service);
      final cardDelete = tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Delete'))
          .onPressed!;
      cardDelete();
      cardDelete();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(_dialogButton('Delete'));
      await tester.pumpAndSettle();
      cardDelete();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(service.deletedIds, ['confirmation-test']);
      service.pendingDelete!.complete();
      await tester.pumpAndSettle();
      expect(service.deletedIds, ['confirmation-test']);
    },
  );

  testWidgets('Delete error stays visible and allows a later retry', (
    tester,
  ) async {
    final service = _Schedules()
      ..deleteError = const ScheduleServiceException(
        'Unable to delete schedule.',
      );
    await _openScreen(tester, service);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(_dialogButton('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to delete schedule.'), findsOneWidget);
    expect(find.text('Test zone'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(service.deletedIds, ['confirmation-test']);
    await tester.tap(_dialogButton('Cancel'));
    await tester.pumpAndSettle();
  });
}
