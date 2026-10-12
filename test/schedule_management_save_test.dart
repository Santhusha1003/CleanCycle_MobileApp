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
  List<Driver> drivers = [];
  List<Vehicle> vehicles = [];

  @override
  Future<List<CollectionSchedule>> getSchedules() async {
    scheduleReads++;
    return List.of(schedules);
  }

  @override
  Future<List<Driver>> getDrivers() async => drivers;

  @override
  Future<List<Vehicle>> getVehicles() async => vehicles;

  @override
  Future<void> createSchedule({required CollectionSchedule schedule}) async {
    createCalls++;
    createdSchedule = schedule;
    await createGate?.future;
    if (createError case final error?) throw error;
    schedules.add(schedule);
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
    expect(find.text('North Zone'), findsOneWidget);
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
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Bad state: write failed'),
      ),
      findsOneWidget,
    );
    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.byIcon(Icons.check),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
    'Firestore permission failures show a safe actionable error in the form',
    (tester) async {
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
          'Firestore denied schedule access (permission-denied). Check the signed-in account role and the published Firestore rules. The schedule was not saved.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('permission context is visible without raw Firebase details', (
    tester,
  ) async {
    final failure = ScheduleSavePermissionException(
      stage: 'saving schedules and resident_schedules',
      cause: const FirebaseServiceException(
        code: 'permission-denied',
        message: 'Private backend diagnostic',
      ),
    );
    final services = _Services()..createError = failure;
    await _openForm(tester, services);
    final zone = find.ancestor(
      of: find.text('Zone'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(zone);
    await tester.enterText(zone, 'North Zone');
    await _tapSave(tester);
    await tester.pumpAndSettle();
    expect(find.text(failure.userMessage), findsOneWidget);
    expect(find.textContaining('Private backend diagnostic'), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(services.schedules, isEmpty);
  });

  testWidgets('Firestore failure is visible in form and retry succeeds', (
    tester,
  ) async {
    final services = _Services()
      ..createError = const FirebaseServiceException(
        code: 'permission-denied',
        message: 'Schedule write denied by real rules.',
      );
    await _openForm(tester, services);
    final zoneField = find.ancestor(
      of: find.text('Zone'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(zoneField);
    await tester.enterText(zoneField, 'Malabe');
    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(
          'Firestore denied schedule access (permission-denied). Check the signed-in account role and the published Firestore rules. The schedule was not saved.',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.widget<TextFormField>(zoneField).controller?.text, 'Malabe');
    services.createError = null;
    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(services.createCalls, 2);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Schedule created successfully.'), findsOneWidget);
  });

  testWidgets(
    'dismissing form during failed save does not update disposed state',
    (tester) async {
      final services = _Services()
        ..createGate = Completer<void>()
        ..createError = StateError('write failed');
      await _openForm(tester, services);
      final zoneField = find.ancestor(
        of: find.text('Zone'),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(zoneField);
      await tester.enterText(zoneField, 'Malabe');
      await _tapSave(tester);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      services.createGate!.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(BottomSheet), findsNothing);
    },
  );

  testWidgets(
    'Driver and vehicle selections are independent and submitted unchanged',
    (tester) async {
      final now = DateTime(2026, 10, 13);
      final services = _Services()
        ..drivers = [
          Driver(
            driverId: 'driver001',
            fullName: 'Driver One',
            email: 'driver@test.invalid',
            phoneNumber: '123',
            licenseNumber: 'DL1',
            status: 'available',
            assignedVehicleId: 'WP-CAB-2341',
            createdAt: now,
            updatedAt: now,
          ),
        ]
        ..vehicles = [
          Vehicle(
            registrationNumber: 'WP-CAB-2341',
            vehicleType: 'truck',
            capacityKg: 1000,
            status: 'available',
            assignedDriverId: 'driver001',
            createdAt: now,
            updatedAt: now,
          ),
          Vehicle(
            registrationNumber: 'WP-CAD-3302',
            vehicleType: 'truck',
            capacityKg: 1000,
            status: 'available',
            assignedDriverId: 'driver003',
            createdAt: now,
            updatedAt: now,
          ),
        ];
      await _openForm(tester, services);
      final driverDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.decoration.labelText == 'Assigned Driver (optional)',
      );
      await tester.ensureVisible(driverDropdown);
      await tester.tap(driverDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Driver One · driver001').last);
      await tester.pumpAndSettle();
      final vehicleDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.decoration.labelText == 'Assigned Vehicle (optional)',
      );
      final field = tester.widget<DropdownButtonFormField<String>>(
        vehicleDropdown,
      );
      expect(field.initialValue, isNull);
      final dropdown = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: vehicleDropdown,
          matching: find.byType(DropdownButton<String>),
        ),
      );
      expect(
        dropdown.items!
            .singleWhere((item) => item.value == 'WP-CAD-3302')
            .enabled,
        isTrue,
      );
      expect(
        dropdown.items!
            .singleWhere((item) => item.value == 'WP-CAB-2341')
            .enabled,
        isTrue,
      );
      // Exercise the actual menu tap, rather than just inspecting its items.
      await tester.ensureVisible(vehicleDropdown);
      await tester.tap(vehicleDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('WP-CAD-3302 · truck').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(vehicleDropdown)
            .initialValue,
        'WP-CAD-3302',
      );
      final zone = find.ancestor(
        of: find.text('Zone'),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(zone);
      await tester.enterText(zone, 'Malabe');
      await _tapSave(tester);
      await tester.pumpAndSettle();
      expect(services.createCalls, 1);
      expect(services.createdSchedule?.assignedVehicleId, 'WP-CAD-3302');
      expect(services.createdSchedule?.assignedDriverId, 'driver001');
    },
  );

  testWidgets(
    'genuine Firestore denial stays visible and optional driver can be cleared',
    (tester) async {
      final now = DateTime(2026, 10, 13);
      final services = _Services()
        ..drivers = [
          Driver(
            driverId: 'driver002',
            fullName: 'Driver Two',
            email: 'driver2@test.invalid',
            phoneNumber: '123',
            licenseNumber: 'DL2',
            status: 'available',
            createdAt: now,
            updatedAt: now,
          ),
        ]
        ..vehicles = [
          Vehicle(
            registrationNumber: 'WP-CAB-2341',
            vehicleType: 'truck',
            capacityKg: 1000,
            status: 'available',
            createdAt: now,
            updatedAt: now,
          ),
        ]
        ..createError = const FirebaseServiceException(
          code: 'permission-denied',
          message: 'Schedule write denied by rules.',
        );
      await _openForm(tester, services);
      final zone = find.ancestor(
        of: find.text('Zone'),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(zone);
      await tester.enterText(zone, 'Malabe');
      final driverDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.decoration.labelText == 'Assigned Driver (optional)',
      );
      final vehicleDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.decoration.labelText == 'Assigned Vehicle (optional)',
      );
      await tester.ensureVisible(driverDropdown);
      await tester.tap(driverDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Driver Two · driver002').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(vehicleDropdown);
      await tester.tap(vehicleDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('WP-CAB-2341 · truck').last);
      await tester.pumpAndSettle();
      await _tapSave(tester);
      await tester.pumpAndSettle();
      expect(find.text('Open Driver Management'), findsNothing);
      expect(find.text('Remove Driver assignment'), findsNothing);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.textContaining('Firestore denied schedule access'),
        findsOneWidget,
      );
      await tester.ensureVisible(driverDropdown);
      await tester.tap(driverDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('No Driver Assigned').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(driverDropdown)
            .initialValue,
        isNull,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(vehicleDropdown)
            .initialValue,
        'WP-CAB-2341',
      );
      services.createError = null;
      await _tapSave(tester);
      await tester.pumpAndSettle();
      expect(services.createdSchedule?.assignedDriverId, isNull);
      expect(services.createdSchedule?.assignedDriverUid, isNull);
      expect(services.createdSchedule?.assignedVehicleId, 'WP-CAB-2341');
      expect(find.text('Schedule created successfully.'), findsOneWidget);
    },
  );

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
