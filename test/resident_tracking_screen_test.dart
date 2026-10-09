import 'dart:async';
import 'package:cleancycle_mobileapp/features/auth/models/app_user.dart';
import 'package:cleancycle_mobileapp/features/auth/data/auth_repository.dart';
import 'package:cleancycle_mobileapp/features/auth/data/user_repository.dart';
import 'package:cleancycle_mobileapp/features/auth/presentation/auth_controller.dart';
import 'package:cleancycle_mobileapp/vishani/models/driver_tracking_model.dart';
import 'package:cleancycle_mobileapp/vishani/screens/live_tracking_screen.dart';
import 'package:cleancycle_mobileapp/vishani/services/tracking_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _User implements User {
  _User(this.uid);
  @override
  final String uid;
  @override
  bool get isAnonymous => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth extends AuthRepository {}

class _Tracking extends TrackingService {
  final streams = <String, StreamController<ResidentTrackingData>>{};
  final calls = <String>[];
  Stream<ResidentTrackingData> stream(String uid, String role) {
    calls.add('$role:$uid');
    return (streams[uid] ??= StreamController<ResidentTrackingData>.broadcast())
        .stream;
  }

  @override
  Stream<ResidentTrackingData> streamResidentTracking(String uid) =>
      stream(uid, 'resident');
  @override
  Stream<ResidentTrackingData> streamDriverTracking(String uid) =>
      stream(uid, 'driver');
}

void main() {
  AppUser profile(String uid, String role) => AppUser(
    uid: uid,
    name: '',
    email: '',
    phone: '',
    role: role,
    addressZone: '',
    emailVerified: true,
    createdAt: null,
  );
  late AuthController auth;
  late _Tracking service;
  setUp(() {
    auth = AuthController(
      authRepository: _Auth(),
      userRepository: UserRepository(),
      firebaseReady: false,
    );
    auth.firebaseUser = _User('one');
    auth.profile = profile('one', 'resident');
    service = _Tracking();
  });
  tearDown(() async {
    auth.dispose();
    for (final stream in service.streams.values) {
      await stream.close();
    }
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(home: LiveTrackingScreen(trackingService: service)),
      ),
    );
  }

  void send(String uid, {String? name, String? message, String? payloadUid}) {
    service.streams[uid]!.add(
      ResidentTrackingData(
        uid: payloadUid ?? uid,
        requestId: name == null ? null : 'request-$uid',
        message: message ?? 'Driver assigned. Tracking is not available yet.',
        driverName: name ?? '',
        vehicleRegistration: name == null ? '' : 'vehicle-$uid',
      ),
    );
  }

  testWidgets(
    'switching resident accounts immediately clears previous assignment',
    (tester) async {
      await open(tester);
      send('one', name: 'First assigned driver');
      await tester.pump();
      expect(find.text('First assigned driver'), findsOneWidget);
      auth.firebaseUser = _User('two');
      auth.profile = profile('two', 'resident');
      auth.notifyListeners();
      await tester.pump();
      expect(find.text('First assigned driver'), findsNothing);
      expect(find.text('vehicle-one'), findsNothing);
      send('two', name: 'Second assigned driver');
      await tester.pump();
      expect(find.text('Second assigned driver'), findsOneWidget);
      expect(find.text('First assigned driver'), findsNothing);
      expect(find.text('Nalin Perera'), findsNothing);
      expect(find.textContaining('25 minutes'), findsNothing);
      expect(find.text('My Home'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('a mismatched UID event cannot display its assignment', (
    tester,
  ) async {
    await open(tester);
    send('one', name: 'Foreign driver', payloadUid: 'two');
    await tester.pump();
    expect(find.text('Foreign driver'), findsNothing);
    expect(find.text('Tracking is not available yet.'), findsOneWidget);
  });
  testWidgets(
    'unassigned request shows pending state without demo driver or map',
    (tester) async {
      await open(tester);
      send(
        'one',
        message: 'Your collection request is awaiting a driver assignment.',
      );
      await tester.pump();
      expect(
        find.textContaining('awaiting a driver assignment'),
        findsOneWidget,
      );
      expect(find.text('Nalin Perera'), findsNothing);
      expect(find.text('WP-NA-4521'), findsNothing);
      expect(find.byIcon(Icons.home), findsNothing);
      expect(find.byTooltip('Call assigned driver'), findsNothing);
    },
  );
  testWidgets('a stream error clears previously displayed driver details', (
    tester,
  ) async {
    await open(tester);
    send('one', name: 'Assigned driver');
    await tester.pump();
    service.streams['one']!.addError(StateError('unavailable'));
    await tester.pump();
    expect(find.text('Assigned driver'), findsNothing);
    expect(
      find.textContaining('Unable to load your tracking data'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'partial request permission failure displays query and code with saved zone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester);
      service.streams['one']!.add(
        const ResidentTrackingData(
          uid: 'one',
          addressZone: 'Kaduwela',
          message: 'Tracking could not be loaded.',
          failures: [
            TrackingReadFailure(
              source: 'special_pickups where userId == one',
              code: 'permission-denied',
            ),
          ],
        ),
      );
      await tester.pump();
      expect(
        find.text(
          'Access denied to special_pickups where userId == one (permission-denied).',
        ),
        findsOneWidget,
      );
      expect(find.text('Saved address / zone: Kaduwela'), findsOneWidget);
      expect(find.text('No active collection request.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'connection error uses a different label from permission denied',
    (tester) async {
      await open(tester);
      service.streams['one']!.add(
        const ResidentTrackingData(
          uid: 'one',
          message: 'Tracking could not be loaded.',
          failures: [
            TrackingReadFailure(
              source: 'collectionRequests',
              code: 'unavailable',
            ),
          ],
        ),
      );
      await tester.pump();
      expect(
        find.text('Unable to load collectionRequests (unavailable).'),
        findsOneWidget,
      );
      expect(find.textContaining('Access denied'), findsNothing);
    },
  );
  testWidgets('Driver uses assigned-trip stream instead of Resident queries', (
    tester,
  ) async {
    auth.profile = profile('one', 'driver');
    await open(tester);
    expect(service.calls, ['driver:one']);
    send('one', message: 'No active collections or trips assigned to you.');
    await tester.pump();
    expect(
      find.text('No active collections or trips assigned to you.'),
      findsOneWidget,
    );
  });
  testWidgets('role change clears old Resident data and switches stream', (
    tester,
  ) async {
    await open(tester);
    send('one', name: 'Previous resident assignment');
    await tester.pump();
    auth.profile = profile('one', 'driver');
    auth.notifyListeners();
    await tester.pump();
    expect(find.text('Previous resident assignment'), findsNothing);
    expect(service.calls, ['resident:one', 'driver:one']);
  });
}
