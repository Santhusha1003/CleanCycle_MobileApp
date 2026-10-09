import 'package:cleancycle_mobileapp/widgets/common/municipal_crud_actions.dart';
import 'package:cleancycle_mobileapp/models/vehicle.dart';
import 'package:cleancycle_mobileapp/models/driver.dart';
import 'package:cleancycle_mobileapp/models/staff.dart';
import 'package:cleancycle_mobileapp/services/municipal/vehicle_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/driver_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/staff_service.dart';
import 'package:cleancycle_mobileapp/screens/vehicle_management_screen.dart';
import 'package:cleancycle_mobileapp/screens/driver_management_screen.dart';
import 'package:cleancycle_mobileapp/screens/staff_management_screen.dart';
import 'package:cleancycle_mobileapp/screens/vehicle_details_screen.dart';
import 'package:cleancycle_mobileapp/screens/driver_details_screen.dart';
import 'package:cleancycle_mobileapp/screens/staff_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Local test storage exercises UI callbacks; no production Firebase writes.
class _Store implements VehicleService, DriverService, StaffService {
  final vehicles = [
    Vehicle(
      registrationNumber: 'DETAIL-001',
      vehicleType: 'Garbage Truck',
      brand: 'Isuzu',
      model: 'N-Series',
      yearManufactured: 2024,
      capacityKg: 5000,
      status: 'available',
      assignedDriverId: 'DRIVER-001',
      assignedZone: 'Test Zone',
      lastServiceDate: DateTime(2026, 9, 1),
      nextServiceDate: DateTime(2026, 12, 1),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];
  final drivers = [
    Driver(
      driverId: 'DRIVER-001',
      fullName: 'Driver Test Person',
      email: 'driver@example.test',
      phoneNumber: '+94771234567',
      licenseNumber: 'LICENSE-001',
      licenseExpiryDate: DateTime(2027, 1, 15),
      assignedVehicleId: 'DETAIL-001',
      assignedZone: 'Test Zone',
      status: 'available',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];
  final staff = [
    Staff(
      staffId: 'STAFF-001',
      fullName: 'Staff Test Person',
      email: 'staff@example.test',
      phoneNumber: '+94779876543',
      position: 'Supervisor',
      assignedZone: 'Test Zone',
      status: 'active',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];
  int updates = 0;
  int deletes = 0;
  @override
  Future<List<Vehicle>> getVehicles() async => List.of(vehicles);
  @override
  Future<List<Driver>> getDrivers() async => List.of(drivers);
  @override
  Future<List<Staff>> getStaffMembers() async => List.of(staff);
  @override
  Future<void> updateVehicle({
    required String registrationNumber,
    required Vehicle vehicle,
  }) async {
    expect(registrationNumber, vehicles.single.registrationNumber);
    vehicles[0] = vehicle;
    updates++;
  }

  @override
  Future<void> updateDriver({
    required String driverId,
    required Driver driver,
  }) async {
    expect(driverId, drivers.single.driverId);
    drivers[0] = driver;
    updates++;
  }

  @override
  Future<void> updateStaff({
    required String staffId,
    required Staff staff,
  }) async {
    expect(staffId, this.staff.single.staffId);
    this.staff[0] = staff;
    updates++;
  }

  @override
  Future<void> deleteVehicle({required String registrationNumber}) async {
    expect(registrationNumber, vehicles.single.registrationNumber);
    vehicles.clear();
    deletes++;
  }

  @override
  Future<void> deleteDriver({required String driverId}) async {
    expect(driverId, drivers.single.driverId);
    drivers.clear();
    deletes++;
  }

  @override
  Future<void> deleteStaff({required String staffId}) async {
    expect(staffId, staff.single.staffId);
    staff.clear();
    deletes++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester,
  Widget screen, {
  double width = 430,
}) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
  expect(find.byType(MunicipalCrudActions), findsOneWidget);
}

void main() {
  final cases =
      <(Widget Function(_Store), String, Type, String, Map<String, String>)>[
        (
          (store) => VehicleManagementScreen(vehicleService: store),
          'DETAIL-001',
          VehicleDetailsScreen,
          'Update Vehicle',
          {
            'Brand': 'Isuzu',
            'Model': 'N-Series',
            'Manufacturing Year': '2024',
            'Capacity': '5000 kg',
            'Assigned Driver ID': 'DRIVER-001',
            'Collection Zone': 'Test Zone',
            'Last Service Date': '01/09/2026',
            'Next Service Date': '01/12/2026',
          },
        ),
        (
          (store) => DriverManagementScreen(driverService: store),
          'Driver Test Person',
          DriverDetailsScreen,
          'Update Driver',
          {
            'Driver ID': 'DRIVER-001',
            'Email': 'driver@example.test',
            'Contact Number': '+94771234567',
            'License Number': 'LICENSE-001',
            'License Expiry Date': '15/01/2027',
            'Assigned Vehicle': 'DETAIL-001',
            'Collection Zone': 'Test Zone',
          },
        ),
        (
          (store) => StaffManagementScreen(staffService: store),
          'Staff Test Person',
          StaffDetailsScreen,
          'Update Staff Member',
          {
            'Staff ID': 'STAFF-001',
            'Position': 'Supervisor',
            'Email': 'staff@example.test',
            'Contact Number': '+94779876543',
            'Assigned Zone': 'Test Zone',
            'Employment Status': 'active',
          },
        ),
      ];
  for (final entry in cases) {
    testWidgets(
      '${entry.$3}: card opens record data and back preserves search',
      (tester) async {
        final store = _Store();
        await _open(tester, entry.$1(store), width: 320);
        await tester.enterText(find.byType(TextField).first, entry.$2);
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.$2).last);
        await tester.pumpAndSettle();
        expect(find.byType(entry.$3), findsOneWidget);
        expect(find.byType(MunicipalCrudActions), findsOneWidget);
        for (final field in entry.$5.entries) {
          await tester.scrollUntilVisible(
            find.text(field.key),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text(field.value), findsWidgets);
          expect(tester.takeException(), isNull);
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byType(TextField).first)
              .controller!
              .text,
          entry.$2,
        );
        expect(store.updates, 0);
        expect(store.deletes, 0);
      },
    );

    testWidgets(
      '${entry.$3}: Edit uses the existing form; delete requires confirmation',
      (tester) async {
        final store = _Store();
        await _open(tester, entry.$1(store));
        await tester.tap(find.text(entry.$2).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        final nameField = find.byType(TextFormField).at(1);
        final updated = entry.$3 == VehicleDetailsScreen
            ? 'Compactor'
            : 'Updated Test Person';
        await tester.enterText(nameField, updated);
        await tester.ensureVisible(find.text(entry.$4));
        await tester.tap(find.text(entry.$4));
        await tester.pumpAndSettle();
        expect(store.updates, 1);
        expect(find.byType(entry.$3), findsOneWidget);
        expect(find.byType(MunicipalCrudActions), findsOneWidget);
        expect(find.text(updated), findsWidgets);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(store.deletes, 0);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(entry.$3), findsOneWidget);
        expect(find.byType(MunicipalCrudActions), findsOneWidget);
        expect(store.deletes, 0);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Delete'),
          ),
        );
        await tester.pumpAndSettle();
        expect(store.deletes, 1);
        expect(find.byType(entry.$3), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Vehicle optional fields use explicit empty values', (
    tester,
  ) async {
    final store = _Store();
    store.vehicles[0] = Vehicle(
      registrationNumber: 'MINIMAL',
      vehicleType: 'Truck',
      capacityKg: 0,
      status: 'available',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await _open(tester, VehicleManagementScreen(vehicleService: store));
    await tester.tap(find.text('MINIMAL'));
    await tester.pumpAndSettle();
    expect(find.text('Not provided'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Next Service Date'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Not recorded'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
