import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

enum NotificationPermissionStatus {
  authorized,
  provisional,
  denied,
  notDetermined,
}

class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<NotificationPermissionStatus> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        return NotificationPermissionStatus.authorized;
      case AuthorizationStatus.provisional:
        return NotificationPermissionStatus.provisional;
      case AuthorizationStatus.denied:
        return NotificationPermissionStatus.denied;
      case AuthorizationStatus.notDetermined:
      default:
        return NotificationPermissionStatus.notDetermined;
    }
  }

  Future<String?> getToken() async {
    developer.log('DEBUG: Calling FirebaseMessaging.instance.getToken()...');

    try {
      final token = await _messaging.getToken().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          developer.log(
            'DEBUG: FirebaseMessaging.getToken() timed out after 20 seconds.',
          );
          return null;
        },
      );

      if (token == null) {
        developer.log('DEBUG: FCM token result: NULL');
        return null;
      }

      developer.log('DEBUG: FCM token result: NON-NULL');
      developer.log('FCM token obtained successfully.');
      return token;
    } on FirebaseException catch (e) {
      developer.log(
        'DEBUG: FirebaseException from getToken: code=${e.code} message=${e.message ?? "null"}',
      );
      return null;
    } on TimeoutException {
      developer.log(
        'DEBUG: TimeoutException from getToken: request exceeded 20 seconds.',
      );
      return null;
    } catch (e, stackTrace) {
      developer.log('DEBUG: Unexpected exception from getToken: $e');
      developer.log('Stack trace: $stackTrace');
      return null;
    }
  }
}
