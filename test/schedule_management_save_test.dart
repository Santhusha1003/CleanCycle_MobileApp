import 'dart:async';

import 'package:cleancycle_mobileapp/models/collection_schedule.dart';
import 'package:cleancycle_mobileapp/models/driver.dart';
import 'package:cleancycle_mobileapp/models/vehicle.dart';
import 'package:cleancycle_mobileapp/screens/schedule_management_screen.dart';
import 'package:cleancycle_mobileapp/services/municipal/driver_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/schedule_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/vehicle_service.dart';
import 'package:cleancycle_mobileapp/services/firebase/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Services implements ScheduleService, DriverService, VehicleService {
  Object? createError;
  Completer<void>? createGate;
  int createCalls = 0;
  int updateCalls = 0;
  int scheduleReads = 0;
  CollectionSchedule? createdSchedule;
  CollectionSchedule? updatedSchedule;
  List<CollectionSchedule> schedules = [];

  @override
  Future<List<CollectionSchedule>> getSchedules() async {
    scheduleReads++;
    return List.of(schedules);
  }

  @override
  Future<List<Driver>> getDrivers() async => const [];

  @override
  Future<List<Vehicle>> getVehicles() async => const [];

  @override
  Future<void> createSchedule({required CollectionSchedule schedule}) async {
    createCalls++;
    createdSchedule = schedule;
    await createGate?.future;
    if (createError case final error?) throw error;
  }

  @override
  Future<void> updateSchedule({
    required String scheduleId,
    required CollectionSchedule schedule,
  }) async {
    updateCalls++;
    updatedSchedule = schedule;
    if (createError case final error?) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected service call: ${invocation.memberName}');
}

Future<void> _openForm(WidgetTester tester, _Services services) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: ScheduleManagementScreen(
        scheduleService: services,
        driverService: services,
        vehicleService: services,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add Schedule'));
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  final save = find.text('Save Schedule');
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pump();
}

CollectionSchedule _existingSchedule() => CollectionSchedule(
  scheduleId: 'existing-1',
  zone: 'North Zone',
  collectionDate: DateTime(2026, 10, 10),
  startTime: '08:00',
  endTime: '17:00',
  wasteType: 'general',
  status: 'scheduled',
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
);

void main() {
  testWidgets('Save validates required fields before calling service', (
    tester,
  ) async {
    final services = _Services();
    await _openForm(tester, services);

    await _tapSave(tester);

    expect(find.text('Zone is required'), findsOneWidget);
    expect(services.createCalls, 0);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('Save creates schedule, closes form, and refreshes list', (
    tester,
  ) async {
    final services = _Services();
    await _openForm(tester, services);
    final zoneField = find.ancestor(
      of: find.text('Zone'),
      matching: find.byType(TextFormField),
    );
    expect(zoneField, findsOneWidget);
    await tester.ensureVisible(zoneField);
    await tester.tap(zoneField);
    await tester.enterText(zoneField, 'North Zone');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(zoneField).controller?.text,
      'North Zone',
    );

    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(services.createCalls, 1);
    expect(services.createdSchedule?.zone, 'North Zone');
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Schedule created successfully.'), findsOneWidget);
    expect(services.scheduleReads, greaterThanOrEqualTo(2));
  });

  testWidgets('Edit submits the existing ID and calls update exactly once', (
    tester,
  ) async {
    final services = _Services()..schedules = [_existingSchedule()];
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleManagementScreen(
          scheduleService: services,
          driverService: services,
          vehicleService: services,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Update Schedule'));
    await tester.tap(find.text('Update Schedule'));
    await tester.pumpAndSettle();

    expect(services.updateCalls, 1);
    expect(services.createCalls, 0);
    expect(services.updatedSchedule?.scheduleId, 'existing-1');
    expect(services.updatedSchedule?.zone, 'North Zone');
    expect(find.text('Schedule updated successfully.'), findsOneWidget);
    expect(services.scheduleReads, greaterThanOrEqualTo(2));
  });

  testWidgets('Save failure keeps form open and shows useful error', (
    tester,
  ) async {
    final services = _Services()..createError = StateError('write failed');
    await _openForm(tester, services);
    final zoneField = find.ancestor(
      of: find.text('Zone'),
      matching: find.byType(TextFormField),
    );
    expect(zoneField, findsOneWidget);
    await tester.ensureVisible(zoneField);
    await tester.tap(zoneField);
    await tester.enterText(zoneField, 'North Zone');
    await tester.pumpAndSettle();

    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(services.createCalls, 1);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Bad state: write failed'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.byIcon(Icons.check),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Firestore permission failures reach the form unchanged', (
    tester,
  ) async {
    final services = _Services()
      ..createError = const FirebaseServiceException(
        code: 'permission-denied',
        message: 'The signed-in role cannot write this schedule.',
      );
    await _openForm(tester, services);
    final zoneField = find.ancestor(
      of: find.text('Zone'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(zoneField);
    await tester.tap(zoneField);
    await tester.enterText(zoneField, 'North Zone');
    await tester.pumpAndSettle();

    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(services.createCalls, 1);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.text(
        'Firestore permission-denied: The signed-in role cannot write this schedule.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('repeated taps while saving submit only once', (tester) async {
    final services = _Services()..createGate = Completer<void>();
    await _openForm(tester, services);
    final zoneField = find.ancestor(
      of: find.text('Zone'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(zoneField);
    await tester.tap(zoneField);
    await tester.enterText(zoneField, 'North Zone');
    await tester.pumpAndSettle();

    await _tapSave(tester);
    await tester.pump();
    expect(services.createCalls, 1);
    final submitButton = find.ancestor(
      of: find.byType(CircularProgressIndicator).last,
      matching: find.byType(ElevatedButton),
    );
    expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pump();
    expect(services.createCalls, 1);

    services.createGate!.complete();
    await tester.pumpAndSettle();
    expect(services.createCalls, 1);
    expect(find.text('Schedule created successfully.'), findsOneWidget);
  });
}
