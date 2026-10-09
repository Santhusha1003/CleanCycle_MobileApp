import 'package:cleancycle_mobileapp/core/theme/app_theme.dart' as auth_theme;
import 'package:cleancycle_mobileapp/models/collection_schedule.dart';
import 'package:cleancycle_mobileapp/models/driver.dart';
import 'package:cleancycle_mobileapp/models/staff.dart';
import 'package:cleancycle_mobileapp/models/vehicle.dart';
import 'package:cleancycle_mobileapp/screens/driver_management_screen.dart';
import 'package:cleancycle_mobileapp/screens/schedule_management_screen.dart';
import 'package:cleancycle_mobileapp/screens/staff_management_screen.dart';
import 'package:cleancycle_mobileapp/screens/vehicle_management_screen.dart';
import 'package:cleancycle_mobileapp/services/municipal/driver_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/schedule_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/staff_service.dart';
import 'package:cleancycle_mobileapp/services/municipal/vehicle_service.dart';
import 'package:cleancycle_mobileapp/theme/app_colors.dart';
import 'package:cleancycle_mobileapp/theme/app_theme.dart' as municipal_theme;
import 'package:cleancycle_mobileapp/widgets/common/municipal_add_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// UI-only test doubles: opening Add must not call any Firestore mutation.
class _ReadOnlyStore
    implements VehicleService, DriverService, StaffService, ScheduleService {
  @override
  Future<List<Vehicle>> getVehicles() async => [];
  @override
  Future<List<Driver>> getDrivers() async => [];
  @override
  Future<List<Staff>> getStaffMembers() async => [];
  @override
  Future<List<CollectionSchedule>> getSchedules() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected service call: ${invocation.memberName}');
}

void main() {
  for (final theme in [
    ('integrated', auth_theme.AppTheme.light),
    ('municipal', municipal_theme.AppTheme.lightTheme),
  ]) {
    for (final width in [320.0, 430.0]) {
      for (final label in [
        'Add Vehicle',
        'Add Driver',
        'Add Staff Member',
        'Add Schedule',
      ]) {
        testWidgets('$label uses shared styling at $width (${theme.$1})', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final store = _ReadOnlyStore();
          final Widget screen = switch (label) {
            'Add Vehicle' => VehicleManagementScreen(vehicleService: store),
            'Add Driver' => DriverManagementScreen(driverService: store),
            'Add Staff Member' => StaffManagementScreen(staffService: store),
            _ => ScheduleManagementScreen(scheduleService: store),
          };
          await tester.pumpWidget(MaterialApp(theme: theme.$2, home: screen));
          // The same shared widget is used while loading and after reads finish.
          expect(find.byType(MunicipalAddButton), findsOneWidget);
          await tester.pumpAndSettle();
          final shared = find.byType(MunicipalAddButton);
          expect(shared, findsOneWidget);
          final button = find.descendant(
            of: shared,
            matching: find.byType(ElevatedButton),
          );
          expect(button, findsOneWidget);
          final style = tester.widget<ElevatedButton>(button).style!;
          expect(style.backgroundColor!.resolve({}), AppColors.primary);
          expect(style.foregroundColor!.resolve({}), AppColors.white);
          expect(style.elevation!.resolve({}), 0);
          expect(style.surfaceTintColor!.resolve({}), Colors.transparent);
          expect(style.alignment, Alignment.center);
          expect(
            style.padding!.resolve({}),
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          );
          expect(style.textStyle!.resolve({})!.fontWeight, FontWeight.w600);
          expect(style.textStyle!.resolve({})!.fontSize, 16);
          final shape = style.shape!.resolve({})! as RoundedRectangleBorder;
          expect(shape.borderRadius, BorderRadius.circular(12));
          expect(tester.getSize(button), Size(width - 32, 48));
          final material = tester.widget<Material>(
            find.descendant(of: button, matching: find.byType(Material)).first,
          );
          expect(material.color, AppColors.primary);
          expect(material.elevation, 0);
          final text = find.descendant(of: shared, matching: find.text(label));
          expect(tester.widget<Text>(text).textAlign, TextAlign.center);
          expect(
            DefaultTextStyle.of(tester.element(text)).style.color,
            AppColors.white,
          );
          expect(
            find.descendant(of: shared, matching: find.byIcon(Icons.add)),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(BottomSheet),
              matching: find.text(label),
            ),
            findsOneWidget,
          );
          expect(find.byType(TextFormField), findsWidgets);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
