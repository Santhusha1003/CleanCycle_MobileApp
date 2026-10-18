import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/collection_schedule.dart';

abstract interface class CollectionScheduleReminderService {
  Future<void> scheduleReminder(CollectionSchedule schedule);
}

/// Schedules a local reminder one hour before the saved collection start time.
/// A stable notification ID makes repeated taps replace the same reminder.
class LocalCollectionScheduleReminderService
    implements CollectionScheduleReminderService {
  LocalCollectionScheduleReminderService({
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  @override
  Future<void> scheduleReminder(CollectionSchedule schedule) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      throw UnsupportedError(
        'Collection reminders are unavailable on this device.',
      );
    }

    final start = _parseStartTime(schedule.startTime);
    final collectionStart = DateTime(
      schedule.collectionDate.year,
      schedule.collectionDate.month,
      schedule.collectionDate.day,
      start.hour,
      start.minute,
    );
    final reminderAt = collectionStart.subtract(const Duration(hours: 1));
    if (!reminderAt.isAfter(DateTime.now())) {
      throw StateError(
        'A reminder cannot be set for a collection that is too soon or has passed.',
      );
    }

    await _initialize();
    final granted = await _requestPermission();
    if (!granted) {
      throw StateError('Notification permission was not granted.');
    }

    tz_data.initializeTimeZones();
    final scheduledAtUtc = tz.TZDateTime.from(reminderAt.toUtc(), tz.UTC);
    await _notifications.zonedSchedule(
      _notificationId(schedule.id),
      'Collection reminder',
      '${schedule.wasteType} collection starts at ${_formatTime(start)}.',
      scheduledAtUtc,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'collection_reminders',
          'Collection reminders',
          channelDescription: 'Reminders for your scheduled collections',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat_notify'),
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(settings);
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'collection_reminders',
        'Collection reminders',
        description: 'Reminders for your scheduled collections',
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  DateTime _parseStartTime(String value) {
    for (final format in [DateFormat('H:mm'), DateFormat('h:mm a')]) {
      try {
        return format.parseStrict(value);
      } on FormatException {
        // Try the other supported stored time format.
      }
    }
    throw const FormatException('The collection start time is invalid.');
  }

  String _formatTime(DateTime time) => DateFormat('h:mm a').format(time);

  int _notificationId(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
