import 'package:cleancycle_mobileapp/navigation/app_routes.dart';
import 'package:cleancycle_mobileapp/navigation/municipal_shell.dart';
import 'package:cleancycle_mobileapp/theme/app_colors.dart';
import 'package:cleancycle_mobileapp/widgets/common/app_primary_button.dart';
import 'package:cleancycle_mobileapp/widgets/common/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final hasDashboard in [true, false]) {
    testWidgets('Back returns to dashboard (existing: $hasDashboard)', (
      tester,
    ) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          initialRoute: hasDashboard ? AppRoutes.municipalDashboard : '/',
          routes: {
            '/': (_) => const Scaffold(body: Text('Direct entry')),
            AppRoutes.municipalDashboard: (_) =>
                const Scaffold(body: Text('Dashboard')),
            '/management': (context) => Scaffold(
              body: TextButton(
                onPressed: () => MunicipalShell.backToDashboard(context),
                child: const Text('Back to dashboard'),
              ),
            ),
          },
        ),
      );
      key.currentState!.pushNamed('/management');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Back to dashboard'), findsNothing);
    });
  }

  testWidgets('Compact icon buttons fit a narrow row and run callbacks', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: Row(
                children: [
                  AppPrimaryButton(
                    label: 'Save',
                    compact: true,
                    icon: Icons.check,
                    onPressed: () => taps++,
                  ),
                  const SizedBox(width: 8),
                  AppSecondaryButton(
                    label: 'Delete',
                    compact: true,
                    destructive: true,
                    icon: Icons.delete,
                    onPressed: () => taps++,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    final secondary = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    expect(secondary.style!.foregroundColor!.resolve({}), AppColors.error);
    await tester.tap(find.text('Save'));
    await tester.tap(find.text('Delete'));
    expect(taps, 2);
  });

  testWidgets('Loading prevents actions for both button variants', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppPrimaryButton(
                label: 'Save',
                compact: true,
                isLoading: true,
                onPressed: () => taps++,
              ),
              AppSecondaryButton(
                label: 'Cancel',
                compact: true,
                isLoading: true,
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    expect(taps, 0);
  });
}
