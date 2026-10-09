import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleancycle_mobileapp/features/auth/data/auth_repository.dart';
import 'package:cleancycle_mobileapp/features/auth/data/user_repository.dart';
import 'package:cleancycle_mobileapp/features/auth/models/app_user.dart';
import 'package:cleancycle_mobileapp/features/auth/presentation/auth_controller.dart';
import 'package:cleancycle_mobileapp/features/profile/presentation/profile_controller.dart';
import 'package:cleancycle_mobileapp/features/profile/presentation/screens/account_settings_screen.dart';
import 'package:cleancycle_mobileapp/models/driver.dart';
import 'package:cleancycle_mobileapp/navigation/app_router.dart';
import 'package:cleancycle_mobileapp/navigation/app_routes.dart';
import 'package:cleancycle_mobileapp/services/municipal/driver_service.dart';
import 'package:cleancycle_mobileapp/vishani/screens/driver_profile_screen.dart';
import 'package:cleancycle_mobileapp/vishani/screens/tracking_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

AppUser _user({String role = 'driver', String email = 'actual@example.test'}) =>
    AppUser(
      uid: 'authenticated-uid',
      name: 'Authenticated Person',
      email: email,
      phone: '0771234567',
      role: role,
      addressZone: 'Home address, not assigned zone',
      emailVerified: true,
      createdAt: null,
    );

class _FirebaseUser implements User {
  @override
  String get uid => 'authenticated-uid';
  @override
  bool get isAnonymous => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Session extends AuthController {
  _Session(AppUser user)
    : super(
        authRepository: AuthRepository(),
        userRepository: UserRepository(),
        firebaseReady: false,
      ) {
    status = AuthStatus.authenticated;
    profile = user;
    firebaseUser = _FirebaseUser();
  }
  int signOutCalls = 0;
  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

class _Profile extends ChangeNotifier implements ProfileController {
  _Profile(this.user);
  @override
  final AppUser user;
  @override
  bool get loading => false;
  @override
  bool get busy => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Driver _record({
  String id = 'DRIVER-REAL',
  String email = ' ACTUAL@example.test ',
  String? authUid = 'authenticated-uid',
}) => Driver(
  driverId: id,
  authUid: authUid,
  fullName: 'Operational Driver',
  email: email,
  phoneNumber: '0779999999',
  licenseNumber: 'LIC-REAL',
  status: 'assigned',
  assignedVehicleId: 'VEHICLE-REAL',
  assignedZone: 'Assigned Zone',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _Drivers implements DriverService {
  _Drivers(this.records);
  final List<Driver> records;
  Exception? error;
  int reads = 0;
  String? requestedUid;
  @override
  Future<Driver?> getDriverForAuthUid({required String authUid}) async {
    reads++;
    requestedUid = authUid;
    if (error != null) throw error!;
    final matches = records
        .where((driver) => driver.authUid == authUid)
        .toList();
    if (matches.length > 1) {
      throw const DriverServiceException(
        'Multiple driver records are linked to this account. Contact support.',
      );
    }
    return matches.isEmpty ? null : matches.single;
  }

  @override
  Future<List<Driver>> getDrivers() async {
    reads++;
    if (error != null) throw error!;
    return records;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected CRUD mutation');
}

Future<_Session> _open(
  WidgetTester tester,
  Widget screen, {
  AppUser? user,
}) async {
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final account = user ?? _user();
  final session = _Session(account);
  final profile = _Profile(account);
  addTearDown(session.dispose);
  addTearDown(profile.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: session),
        ChangeNotifierProvider<ProfileController>.value(value: profile),
      ],
      child: MaterialApp(
        home: screen,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return session;
}

void main() {
  testWidgets(
    'Actual Driver Profile tab shows authenticated and matched driver details',
    (tester) async {
      final records = _Drivers([
        _record(),
        _record(
          id: 'OTHER',
          email: 'other@example.test',
          authUid: 'another-uid',
        ),
      ]);
      await _open(tester, TrackingDashboardScreen(driverService: records));
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(DriverProfileScreen), findsOneWidget);
      for (final value in [
        'Authenticated Person',
        'DRIVER-REAL',
        'actual@example.test',
        '0771234567',
        'VEHICLE-REAL',
        'Assigned Zone',
        'assigned',
      ]) {
        expect(find.text(value), findsOneWidget);
      }
      expect(find.textContaining('Resident ID'), findsNothing);
      expect(records.requestedUid, 'authenticated-uid');
      expect(find.text('Vishani Somarathna'), findsNothing);
      expect(find.text('Return to Home'), findsNothing);
      expect(find.byIcon(Icons.drive_eta_rounded), findsOneWidget);
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        3,
      );
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        0,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Driver header opens guarded Driver Profile route', (
    tester,
  ) async {
    await _open(tester, const TrackingDashboardScreen());
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(DriverProfileScreen), findsOneWidget);
    expect(find.byType(AccountSettingsScreen), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TrackingDashboardScreen), findsOneWidget);
  });

  testWidgets('Resident profile route retains existing Account Settings', (
    tester,
  ) async {
    await _open(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: const Text('Open resident profile'),
          ),
        ),
      ),
      user: _user(role: 'resident'),
    );
    await tester.tap(find.text('Open resident profile'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountSettingsScreen), findsOneWidget);
    expect(find.byType(DriverProfileScreen), findsNothing);
    expect(find.text('Authenticated Person'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Missing driver shows account fields without guessing assignment or ID',
    (tester) async {
      await _open(tester, DriverProfileScreen(driverService: _Drivers([])));
      expect(
        find.text('No driver record linked to this account.'),
        findsOneWidget,
      );
      expect(find.text('Not available'), findsNWidgets(4));
      expect(find.text('Home address, not assigned zone'), findsNothing);
      expect(find.text('authenticated-uid'), findsNothing);
    },
  );

  testWidgets('Ambiguous UID mapping never chooses another driver record', (
    tester,
  ) async {
    await _open(
      tester,
      DriverProfileScreen(
        driverService: _Drivers([_record(), _record(id: 'DUPLICATE')]),
      ),
    );
    expect(find.textContaining('Multiple driver records'), findsOneWidget);
    expect(find.text('DRIVER-REAL'), findsNothing);
    expect(find.text('DUPLICATE'), findsNothing);
  });

  testWidgets(
    'Load errors retain account information and Retry reloads real service',
    (tester) async {
      final records = _Drivers([])..error = Exception('permission-denied');
      await _open(tester, DriverProfileScreen(driverService: records));
      expect(
        find.text('Unable to load driver details. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Authenticated Person'), findsOneWidget);
      records.error = null;
      records.records.add(_record());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('DRIVER-REAL'), findsOneWidget);
      expect(records.reads, 2);
    },
  );

  testWidgets('Sign Out invokes existing AuthController signOut', (
    tester,
  ) async {
    final auth = await _open(
      tester,
      DriverProfileScreen(driverService: _Drivers([])),
    );
    await tester.ensureVisible(find.text('Sign Out'));
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 1);
  });
}
