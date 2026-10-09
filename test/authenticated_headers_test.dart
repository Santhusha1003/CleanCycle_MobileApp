import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/home_dashboard_screen.dart';
import 'package:cleancycle_mobileapp/features/auth/data/auth_repository.dart';
import 'package:cleancycle_mobileapp/features/auth/data/user_repository.dart';
import 'package:cleancycle_mobileapp/features/auth/models/app_user.dart';
import 'package:cleancycle_mobileapp/features/auth/presentation/auth_controller.dart';
import 'package:cleancycle_mobileapp/features/profile/presentation/profile_controller.dart';
import 'package:cleancycle_mobileapp/features/notifications/presentation/notification_settings_screen.dart';
import 'package:cleancycle_mobileapp/navigation/app_router.dart';
import 'package:cleancycle_mobileapp/screens/municipal_dashboard_screen.dart';
import 'package:cleancycle_mobileapp/screens/reports_analytics_screen.dart';
import 'package:cleancycle_mobileapp/services/municipal/municipal_analytics_service.dart';
import 'package:cleancycle_mobileapp/vishani/screens/tracking_dashboard_screen.dart';
import 'package:cleancycle_mobileapp/widgets/common/authenticated_user_greeting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// All profile and analytics fixtures are local, never production Firebase data.
// ignore: subtype_of_sealed_class
class _ProfileDocument implements DocumentSnapshot<Map<String, dynamic>> {
  _ProfileDocument(this.role, this.name);
  final String role;
  final String name;
  @override
  String get id => 'logged-in-header-test';
  @override
  Map<String, dynamic> data() => {
    'name': name,
    'role': role,
    'emailVerified': true,
  };
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FirebaseUser implements User {
  @override
  String get uid => 'logged-in-header-test';
  @override
  bool get isAnonymous => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile extends ChangeNotifier implements ProfileController {
  _Profile(this.user);
  @override
  AppUser? user;
  void rename(String name) {
    user = user!.copyWith(name: name);
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Analytics implements MunicipalAnalyticsService {
  @override
  Future<MunicipalAnalyticsSummary> getMunicipalAnalyticsSummary() async =>
      const MunicipalAnalyticsSummary(
        totalVehicles: 0,
        availableVehicles: 0,
        maintenanceVehicles: 0,
        totalDrivers: 0,
        availableDrivers: 0,
        assignedDrivers: 0,
        totalStaff: 0,
        activeStaff: 0,
        todayCollections: 0,
        completedToday: 0,
        scheduledToday: 0,
        inProgressToday: 0,
        cancelledToday: 0,
        collectionsByWasteType: {},
        collectionsByZone: {},
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AuthController _session(AppUser profile) =>
    AuthController(
        authRepository: AuthRepository(),
        userRepository: UserRepository(),
        firebaseReady: false,
      )
      ..status = AuthStatus.authenticated
      ..profile = profile
      ..firebaseUser = _FirebaseUser();

void main() {
  final screens = <(String, String, Widget Function())>[
    ('resident', 'Resident', () => const HomeDashboardScreen()),
    ('driver', 'Driver', () => const TrackingDashboardScreen()),
    (
      'municipal_officer',
      'Municipal dashboard',
      () => MunicipalDashboardScreen(analyticsService: _Analytics()),
    ),
    (
      'municipal_officer',
      'Municipal reports',
      () => ReportsAnalyticsScreen(analyticsService: _Analytics()),
    ),
  ];
  for (final entry in screens) {
    testWidgets(
      '${entry.$2} header shows profile name, live updates and opens existing notifications UI',
      (tester) async {
        tester.view.physicalSize = const Size(650, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final user = AppUser.fromFirestore(
          _ProfileDocument(entry.$1, 'Header Test User'),
        );
        final auth = _session(user);
        final profile = _Profile(user);
        addTearDown(auth.dispose);
        addTearDown(profile.dispose);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthController>.value(value: auth),
              ChangeNotifierProvider<ProfileController>.value(value: profile),
            ],
            child: MaterialApp(
              home: entry.$3(),
              onGenerateRoute: AppRouter.generateRoute,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Hi, Header Test User 👋'), findsOneWidget);
        expect(find.text('Hi, Santhusha!'), findsNothing);
        profile.rename('Updated Name');
        await tester.pumpAndSettle();
        expect(find.text('Hi, Updated Name 👋'), findsOneWidget);
        expect(find.text('Hi, Header Test User 👋'), findsNothing);
        if (entry.$1 == 'municipal_officer') {
          expect(find.text('CleanCycle'), findsOneWidget);
          expect(find.text('Municipal Operations'), findsOneWidget);
        }
        final bell = entry.$2 == 'Municipal dashboard'
            ? find.byIcon(Icons.notifications_outlined)
            : find.byTooltip('Notifications');
        await tester.tap(bell);
        await tester.pumpAndSettle();
        expect(find.byType(NotificationSettingsScreen), findsOneWidget);
        expect(find.text('Collection reminders'), findsOneWidget);
        expect(find.text('Special pickup updates'), findsOneWidget);
        expect(find.text('Service updates'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Hi, Updated Name 👋'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'Greeting can use AuthController profile without another profile reader',
    (tester) async {
      final user = AppUser.fromFirestore(
        _ProfileDocument('resident', 'Stored Profile Name'),
      );
      final auth = _session(user);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: auth,
          child: const MaterialApp(
            home: Scaffold(body: AuthenticatedUserGreeting()),
          ),
        ),
      );
      expect(find.text('Hi, Stored Profile Name 👋'), findsOneWidget);
    },
  );

  testWidgets('Missing name stays generic; a long name fits a compact header', (
    tester,
  ) async {
    final profile = _Profile(
      AppUser.fromFirestore(_ProfileDocument('driver', '')),
    );
    addTearDown(profile.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<ProfileController>.value(
        value: profile,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 150, child: AuthenticatedUserGreeting()),
          ),
        ),
      ),
    );
    expect(find.text('Hi there 👋'), findsOneWidget);
    profile.rename(
      'A very long full name from the authenticated Firestore profile',
    );
    await tester.pump();
    final text = tester.widget<Text>(find.textContaining('Hi, A very long'));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
