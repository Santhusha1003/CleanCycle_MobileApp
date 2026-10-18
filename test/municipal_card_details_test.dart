import 'package:cleancycle_mobileapp/screens/driver_management_screen.dart';
import 'package:cleancycle_mobileapp/screens/vehicle_management_screen.dart';
import 'package:cleancycle_mobileapp/widgets/common/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/tracking_firestore.dart';

void main() {
  for (final driver in [true, false]) {
    testWidgets(
      '${driver ? 'Driver' : 'Vehicle'} card opens details and returns to list',
      (tester) async {
        final db = TrackingFirestoreFixture();
        db.documents.removeWhere(
          (path, _) =>
              path.startsWith('vehicles/') && path != 'vehicles/ABC-001',
        );
        addTearDown(db.dispose);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final name = driver ? 'Driver One' : 'ABC-001';
        await tester.pumpWidget(
          MaterialApp(
            home: driver
                ? DriverManagementScreen(firestore: db)
                : VehicleManagementScreen(firestore: db),
          ),
        );
        await tester.pumpAndSettle();
        final card = find
            .ancestor(of: find.text(name), matching: find.byType(AppCard))
            .first;
        expect(tester.widget<AppCard>(card).onTap, isNotNull);
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
        expect(
          find.text(driver ? 'Driver Details' : 'Vehicle Details'),
          findsOneWidget,
        );
        expect(find.text(name), findsWidgets);
        expect(find.text(driver ? 'DL-1' : '1000 kg'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(
          find.text(driver ? 'Driver Management' : 'Vehicle Management'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${driver ? 'Driver' : 'Vehicle'} Edit and Delete remain independent of card navigation',
      (tester) async {
        final db = TrackingFirestoreFixture();
        db.documents.removeWhere(
          (path, _) =>
              path.startsWith('vehicles/') && path != 'vehicles/ABC-001',
        );
        addTearDown(db.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: driver
                ? DriverManagementScreen(firestore: db)
                : VehicleManagementScreen(firestore: db),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit').first);
        await tester.pumpAndSettle();
        expect(
          find.text(driver ? 'Edit Driver' : 'Edit Vehicle'),
          findsOneWidget,
        );
        expect(
          find.text(driver ? 'Driver Details' : 'Vehicle Details'),
          findsNothing,
        );
        // Dismiss the sheet without changing the underlying record.
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).first,
        );
        navigator.pop();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete').first);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.text(driver ? 'Driver Details' : 'Vehicle Details'),
          findsNothing,
        );
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(
          db.documents.containsKey(
            driver ? 'drivers/municipal-driver-1' : 'vehicles/ABC-001',
          ),
          isTrue,
        );
        await tester.tap(find.text('View details').first);
        await tester.pumpAndSettle();
        expect(
          find.text(driver ? 'Driver Details' : 'Vehicle Details'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Edit').last);
        await tester.tap(find.text('Edit').last);
        await tester.pumpAndSettle();
        expect(
          find.text(driver ? 'Edit Driver' : 'Edit Vehicle'),
          findsOneWidget,
        );
        navigator.pop();
        await tester.pumpAndSettle();
        expect(
          find.text(driver ? 'Driver Details' : 'Vehicle Details'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
