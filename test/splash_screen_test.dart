import 'package:cleancycle_mobileapp/app.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/home_dashboard_screen.dart';
import 'package:cleancycle_mobileapp/features/auth/data/auth_repository.dart';
import 'package:cleancycle_mobileapp/features/auth/data/user_repository.dart';
import 'package:cleancycle_mobileapp/features/auth/models/app_user.dart';
import 'package:cleancycle_mobileapp/features/auth/presentation/auth_controller.dart';
import 'package:cleancycle_mobileapp/features/auth/presentation/screens/auth_gate.dart';
import 'package:cleancycle_mobileapp/features/auth/presentation/screens/login_screen.dart';
import 'package:cleancycle_mobileapp/navigation/municipal_shell.dart';
import 'package:cleancycle_mobileapp/screens/splash_screen.dart';
import 'package:cleancycle_mobileapp/vishani/screens/tracking_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _User implements User {
  @override
  String get uid => 'splash-session-test';
  @override
  bool get isAnonymous => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('Registered CleanCycle logo contains decodable artwork', () async {
    final data = await rootBundle.load(SplashScreen.logoAsset);
    expect(
      data.lengthInBytes,
      greaterThan(0),
      reason: 'assets/images/logo.png must contain the actual logo image.',
    );
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final frame = await codec.getNextFrame();
    expect(frame.image.width, greaterThan(0));
    expect(frame.image.height, greaterThan(0));
    frame.image.dispose();
    codec.dispose();
  });

  testWidgets('App displays splash for seven seconds then signed-out Login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CleanCycleApp(firebaseReady: false));
    expect(find.text('CleanCycle'), findsOneWidget);
    expect(find.text('Clean Today, Greener Tomorrow'), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
    final logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, 'assets/images/logo.png');
    expect(logo.fit, BoxFit.contain);
    expect(find.byType(LoginScreen), findsNothing);
    await tester.pump(const Duration(milliseconds: 6999));
    expect(find.byType(LoginScreen), findsNothing);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, closeTo(6999 / 7000, 0.001));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.byType(AuthGate), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Loading...'), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final role in ['resident', 'driver', 'municipal_officer']) {
    testWidgets(
      'Splash preserves authenticated $role session and AuthGate destination',
      (tester) async {
        tester.view.physicalSize = const Size(650, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth =
            AuthController(
                authRepository: AuthRepository(),
                userRepository: UserRepository(),
                firebaseReady: false,
              )
              ..status = AuthStatus.authenticated
              ..firebaseUser = _User()
              ..profile = AppUser(
                uid: 'splash-session-test',
                name: 'Splash Test',
                email: '',
                phone: '',
                role: role,
                addressZone: '',
                emailVerified: true,
                createdAt: null,
              );
        addTearDown(auth.dispose);
        await tester.pumpWidget(
          ChangeNotifierProvider<AuthController>.value(
            value: auth,
            child: const MaterialApp(home: SplashScreen()),
          ),
        );
        expect(find.byType(AuthGate), findsNothing);
        await tester.pump(SplashScreen.duration);
        await tester.pump();
        expect(find.byType(AuthGate), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(auth.firebaseUser!.uid, 'splash-session-test');
        expect(auth.profile!.role, role);
        switch (role) {
          case 'resident':
            expect(find.byType(HomeDashboardScreen), findsOneWidget);
          case 'driver':
            expect(find.byType(TrackingDashboardScreen), findsOneWidget);
          case 'municipal_officer':
            expect(find.byType(MunicipalShell), findsOneWidget);
        }
      },
    );
  }

  testWidgets(
    'Early removal disposes the launch controller without navigation',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const MaterialApp(home: Text('Replacement')));
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Replacement'), findsOneWidget);
      expect(find.byType(AuthGate), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Small Android splash fits with large text and reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.6),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const SplashScreen(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Loading...'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
