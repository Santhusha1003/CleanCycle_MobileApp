import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../auth/data/user_repository.dart';

const _androidChannel = AndroidNotificationChannel(
  'cleancycle_default',
  'CleanCycle updates',
  description: 'Collection reminders and service messages',
  importance: Importance.high,
);

/// Must be a top-level function so the FCM background isolate can find it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  await FcmService.displayLocally(message);
}

/// Permission, token persistence, and local display of FCM messages.
class FcmService {
  FcmService({required UserRepository userRepository}) : _users = userRepository;

  final UserRepository _users;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  String? _uid;
  bool _ready = false;

  static const _androidInit = AndroidInitializationSettings('@drawable/ic_stat_notify');
  static const _darwinInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (!_supported || _ready) return;
    await _local.initialize(
      const InitializationSettings(android: _androidInit, iOS: _darwinInit),
    );
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_androidChannel);
    await android?.requestNotificationsPermission();

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(displayLocally);
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final uid = _uid;
      if (uid == null) return;
      await _users.saveFcmToken(uid, token);
    });
    _ready = true;
  }

  /// Called after a successful login / registration.
  Future<void> attachUser(String uid) async {
    _uid = uid;
    if (!_supported) return;
    try {
      await initialize();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _users.saveFcmToken(uid, token);
      }
    } catch (error) {
      debugPrint('FCM attach failed: $error');
    }
  }

  void detachUser() {
    _uid = null;
  }

  /// Used for both foreground and background isolates.
  static Future<void> displayLocally(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(android: _androidInit, iOS: _darwinInit),
    );
    await plugin.show(
      notification.hashCode,
      notification.title ?? 'CleanCycle',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_stat_notify',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
