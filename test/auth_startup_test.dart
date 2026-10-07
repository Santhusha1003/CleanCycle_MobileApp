import 'package:cleancycle_mobileapp/collection_schedule/screens/collection_schedule_screen.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/collection_history_screen.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/missed_collection_report_screen.dart';
import 'package:cleancycle_mobileapp/core/constants/app_roles.dart';
import 'package:cleancycle_mobileapp/features/auth/data/auth_repository.dart';
import 'package:cleancycle_mobileapp/features/auth/data/email_otp.dart';
import 'package:cleancycle_mobileapp/features/auth/data/user_repository.dart';
import 'package:cleancycle_mobileapp/features/auth/models/app_user.dart';
import 'package:cleancycle_mobileapp/features/auth/presentation/auth_controller.dart';
import 'package:cleancycle_mobileapp/features/auth/presentation/screens/auth_gate.dart';
import 'package:cleancycle_mobileapp/features/auth/presentation/screens/login_screen.dart';
import 'package:cleancycle_mobileapp/features/auth/presentation/screens/verification_screen.dart';
import 'package:cleancycle_mobileapp/features/placeholders/app_shell.dart';
import 'package:cleancycle_mobileapp/navigation/municipal_shell.dart';
import 'package:cleancycle_mobileapp/navigation/app_router.dart';
import 'package:cleancycle_mobileapp/navigation/app_routes.dart';
import 'package:cleancycle_mobileapp/screens/schedule_management_screen.dart';
import 'package:cleancycle_mobileapp/features/profile/presentation/screens/account_settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cleancycle_mobileapp/features/profile/presentation/profile_controller.dart';
import 'package:cleancycle_mobileapp/features/placeholders/home_resident_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _User implements User {
  _User({this.isAnonymous = false});
  @override
  final bool isAnonymous;
  @override
  String get uid => 'auth-startup-test';
  @override
  String get email => 'startup@example.test';
  @override
  bool get emailVerified => false;
  @override
  List<UserInfo> get providerData => [
    UserInfo.fromJson({
      'providerId': 'password',
      'uid': 'startup@example.test',
      'isAnonymous': false,
      'isEmailVerified': false,
    }),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth extends AuthRepository {
  _Auth(this.user);
  User? user;
  bool rejectLogin = false;
  String? resetEmail;
  @override
  User? get currentUser => user;
  @override
  Stream<User?> authStateChanges() => Stream.value(user);
  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (rejectLogin) throw FirebaseAuthException(code: 'invalid-credential');
    return user = _User();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetEmail = email;
  }

  @override
  Future<User?> reloadCurrentUser() async => user;
  @override
  Future<void> signOut() async {
    user = null;
  }
}

class _Users extends UserRepository {
  _Users({this.verified = false, this.role = AppRoles.resident});
  bool verified;
  final String role;
  @override
  Future<({String hash, DateTime expiresAt})?> getEmailOtp(String uid) async =>
      (
        hash: EmailOtp.hash('123456', uid),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
  @override
  Future<void> markEmailOtpVerified(String uid) async {
    verified = true;
  }

  @override
  Future<AppUser?> getById(String uid) async => AppUser(
    uid: uid,
    name: 'Test',
    email: 'startup@example.test',
    phone: '',
    role: role,
    addressZone: '',
    emailVerified: verified,
    createdAt: null,
  );
  @override
  Future<void> updateLastLogin(String uid) async {}
  @override
  Stream<AppUser?> watchById(String uid) => Stream.fromFuture(getById(uid));
  @override
  Future<void> clearFcmToken(String uid) async {}
}

class _Database implements FirebaseFirestore {
  Map<String, dynamic>? written;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, 'users');
    return _Collection(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test double captures the real repository payload without touching Firebase.
// ignore: subtype_of_sealed_class
class _Collection implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.database);
  final _Database database;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    expect(path, 'auth-startup-test');
    return _Document(database);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Document implements DocumentReference<Map<String, dynamic>> {
  _Document(this.database);
  final _Database database;
  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    database.written = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RouteProbe extends StatelessWidget {
  const _RouteProbe({required this.routes, required this.destinations});
  final List<String> routes;
  final Map<String, Widget> destinations;
  @override
  Widget build(BuildContext context) {
    for (final name in routes) {
      final route =
          AppRouter.generateRoute(RouteSettings(name: name))
              as MaterialPageRoute;
      final guard = route.builder(context) as StatelessWidget;
      destinations[name] = guard.build(context);
    }
    return const SizedBox.shrink();
  }
}

void main() {
  Future<AuthController> restored({
    User? user,
    bool verified = false,
    String role = AppRoles.resident,
  }) async {
    final controller = AuthController(
      authRepository: _Auth(user),
      userRepository: _Users(verified: verified, role: role),
      firebaseReady: true,
    );
    addTearDown(controller.dispose);
    for (var i = 0; i < 4; i++) {
      await Future<void>.value();
    }
    return controller;
  }

  Future<Widget> gate(WidgetTester tester, AuthController controller) async {
    late Widget destination;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: Builder(
          builder: (context) {
            // Inspect the real gate's routing decision without mounting home pages
            // that need unrelated Profile/FCM providers.
            destination = const AuthGate().build(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return destination;
  }

  testWidgets('Restored anonymous development session opens Login', (
    tester,
  ) async {
    final controller = await restored(user: _User(isAnonymous: true));
    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.firebaseUser, isNull);
    expect(await gate(tester, controller), isA<LoginScreen>());
  });

  testWidgets(
    'Every Municipal route retains its real destination behind the role guard',
    (tester) async {
      final controller = await restored(
        user: _User(),
        verified: true,
        role: AppRoles.municipalOfficer,
      );
      final destinations = <String, Widget>{};
      final routes = [
        ...MunicipalShell.routes,
        AppRoutes.scheduleManagement,
        AppRoutes.profile,
      ];
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: _RouteProbe(routes: routes, destinations: destinations),
        ),
      );
      for (final name in MunicipalShell.routes) {
        final shell = (destinations[name] as Theme).child as MunicipalShell;
        expect(shell.initialRoute, name);
      }
      expect(
        (destinations[AppRoutes.scheduleManagement] as Theme).child,
        isA<ScheduleManagementScreen>(),
      );
      expect(destinations[AppRoutes.profile], isA<AccountSettingsScreen>());
    },
  );

  for (final role in [null, AppRoles.resident, AppRoles.driver]) {
    testWidgets('Municipal named routes reject unauthorized $role sessions', (
      tester,
    ) async {
      final controller = await restored(
        user: role == null ? null : _User(),
        verified: true,
        role: role ?? AppRoles.resident,
      );
      final destinations = <String, Widget>{};
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: _RouteProbe(
            routes: [...MunicipalShell.routes, AppRoutes.scheduleManagement],
            destinations: destinations,
          ),
        ),
      );
      expect(destinations.values, everyElement(isA<AuthGate>()));
    });
  }

  testWidgets('Resident routes expose the merged Member 02 screens', (
    tester,
  ) async {
    final controller = await restored(
      user: _User(),
      verified: true,
      role: AppRoles.resident,
    );
    final destinations = <String, Widget>{};
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: _RouteProbe(
          routes: [
            AppRoutes.collectionSchedule,
            AppRoutes.collectionHistory,
            AppRoutes.missedCollection,
          ],
          destinations: destinations,
        ),
      ),
    );
    expect(
      destinations[AppRoutes.collectionSchedule],
      isA<CollectionScheduleScreen>(),
    );
    expect(
      destinations[AppRoutes.collectionHistory],
      isA<CollectionHistoryScreen>(),
    );
    expect(
      destinations[AppRoutes.missedCollection],
      isA<MissedCollectionReportScreen>(),
    );
  });

  for (final role in [null, AppRoles.driver, AppRoles.municipalOfficer]) {
    testWidgets(
      'Resident collection routes reject unauthorized $role sessions',
      (tester) async {
        final controller = await restored(
          user: role == null ? null : _User(),
          verified: true,
          role: role ?? AppRoles.resident,
        );
        final destinations = <String, Widget>{};
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: controller,
            child: _RouteProbe(
              routes: [
                AppRoutes.collectionSchedule,
                AppRoutes.collectionHistory,
                AppRoutes.missedCollection,
              ],
              destinations: destinations,
            ),
          ),
        );
        expect(destinations.values, everyElement(isA<AuthGate>()));
      },
    );
  }

  testWidgets('Signed-out startup opens Login', (tester) async {
    final controller = await restored();
    expect(await gate(tester, controller), isA<LoginScreen>());
  });

  testWidgets('Restored unverified session opens Login and blocks home', (
    tester,
  ) async {
    final controller = await restored(user: _User());
    expect(controller.needsEmailVerification, isTrue);
    expect(await gate(tester, controller), isA<LoginScreen>());
  });

  testWidgets('Explicit login with an unverified account opens Verification', (
    tester,
  ) async {
    final controller = await restored(user: _User());
    expect(
      await controller.signInWithEmail(
        email: 'startup@example.test',
        password: 'test-password',
      ),
      isTrue,
    );
    expect(await gate(tester, controller), isA<VerificationScreen>());
  });

  testWidgets('Registration awaiting OTP still opens Verification', (
    tester,
  ) async {
    final controller = await restored(user: _User());
    controller.awaitingEmailOtp = true;
    expect(await gate(tester, controller), isA<VerificationScreen>());
  });

  for (final role in AppRoles.all) {
    testWidgets('Verified restored $role session retains role-based home', (
      tester,
    ) async {
      final controller = await restored(
        user: _User(),
        verified: true,
        role: role,
      );
      expect(controller.profile?.role, role);
      final destination = await gate(tester, controller);
      expect(
        destination,
        role == AppRoles.municipalOfficer ? isA<Theme>() : isA<AppShell>(),
      );
      if (destination is Theme) {
        expect(destination.child, isA<MunicipalShell>());
      }
    });
  }

  for (final role in AppRoles.all) {
    test('Signup request $role cannot grant privileged access', () async {
      final database = _Database();
      await UserRepository(firestore: database).createResidentProfile(
        authUser: _User(),
        name: 'Test',
        phone: '0771234567',
        addressZone: 'Kaduwela',
        requestedRole: role,
      );
      expect(database.written!['role'], AppRoles.resident);
      expect(database.written!['requestedRole'], role);
    });
    testWidgets('Normal login routes approved $role to its existing home', (
      tester,
    ) async {
      final auth = _Auth(null);
      final users = _Users(verified: true, role: role);
      final controller = AuthController(
        authRepository: auth,
        userRepository: users,
        firebaseReady: true,
      );
      for (var i = 0; i < 4; i++) {
        await Future<void>.value();
      }
      expect(
        await controller.signInWithEmail(
          email: 'startup@example.test',
          password: 'test-password',
        ),
        isTrue,
      );
      expect(controller.profile!.role, role);
      final profile = ProfileController(
        userRepository: users,
        authRepository: auth,
        authController: controller,
      );
      if (role == AppRoles.municipalOfficer) {
        final destination = await gate(tester, controller) as Theme;
        expect(destination.child, isA<MunicipalShell>());
        await tester.pumpWidget(const SizedBox.shrink());
        profile.dispose();
        controller.dispose();
        return;
      }
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: controller),
            ChangeNotifierProvider.value(value: profile),
          ],
          child: const MaterialApp(home: AuthGate()),
        ),
      );
      await tester.pumpAndSettle();
      final type = switch (role) {
        AppRoles.driver => DriverHomePlaceholder,
        AppRoles.municipalOfficer => OfficerDashboardPlaceholder,
        _ => HomeResidentPlaceholder,
      };
      expect(find.byType(type), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      profile.dispose();
      controller.dispose();
    });
  }

  test(
    'Invalid credentials retain existing errors; reset remains available',
    () async {
      final auth = _Auth(null)..rejectLogin = true;
      final controller = AuthController(
        authRepository: auth,
        userRepository: _Users(),
        firebaseReady: true,
      );
      addTearDown(controller.dispose);
      for (var i = 0; i < 4; i++) {
        await Future<void>.value();
      }
      expect(
        await controller.signInWithEmail(
          email: 'startup@example.test',
          password: 'wrong-password',
        ),
        isFalse,
      );
      expect(controller.errorMessage, isNotEmpty);
      expect(controller.profile, isNull);
      expect(
        await controller.sendPasswordReset('startup@example.test'),
        isTrue,
      );
      expect(auth.resetEmail, 'startup@example.test');
    },
  );

  testWidgets(
    'OTP rejects wrong codes and opens approved role home after verification',
    (tester) async {
      final users = _Users(role: AppRoles.driver);
      final controller = AuthController(
        authRepository: _Auth(_User()),
        userRepository: users,
        firebaseReady: true,
      );
      addTearDown(controller.dispose);
      for (var i = 0; i < 4; i++) {
        await Future<void>.value();
      }
      controller.awaitingEmailOtp = true;
      expect(await gate(tester, controller), isA<VerificationScreen>());
      expect(await controller.verifyEmailOtp('654321'), isFalse);
      expect(controller.errorMessage, contains('incorrect'));
      expect(controller.needsEmailVerification, isTrue);
      expect(await controller.verifyEmailOtp('123456'), isTrue);
      expect(controller.needsEmailVerification, isFalse);
      expect(controller.profile!.role, AppRoles.driver);
      expect(await gate(tester, controller), isA<AppShell>());
    },
  );

  test('Sign out clears permission to enter the verification flow', () async {
    final controller = await restored(user: _User());
    await controller.signInWithEmail(
      email: 'startup@example.test',
      password: 'test-password',
    );
    expect(controller.canShowEmailVerification, isTrue);
    await controller.signOut();
    expect(controller.canShowEmailVerification, isFalse);
  });
}
