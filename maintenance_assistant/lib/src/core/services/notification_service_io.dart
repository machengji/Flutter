import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    } catch (error) {
      debugPrint('Error setting local location: $error');
    }

    const initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettingsIOS = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (_) async {},
    );

    const channel = fln.AndroidNotificationChannel(
      'anchor_channel_v3',
      'Anchors V3',
      description: 'Daily anchor reminders',
      importance: fln.Importance.max,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>();

    final grantedNotification =
        await androidImplementation?.requestNotificationsPermission();
    final grantedAlarm =
        await androidImplementation?.requestExactAlarmsPermission();

    final iosImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.IOSFlutterLocalNotificationsPlugin>();
    final grantedIOSNotification =
        await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    PermissionStatus? batteryOptimizationStatus;
    if (defaultTargetPlatform == TargetPlatform.android) {
      batteryOptimizationStatus =
          await Permission.ignoreBatteryOptimizations.request();
    }

    debugPrint('Permission Status:');
    debugPrint('  Android Notifications: $grantedNotification');
    debugPrint('  iOS Notifications: $grantedIOSNotification');
    debugPrint('  Exact Alarms: $grantedAlarm');
    debugPrint('  Battery Optimization: $batteryOptimizationStatus');
  }

  Future<void> showInstantNotification({
    String title = '提醒通知',
    String body = '你设置的提醒已经到了',
  }) async {
    const androidDetails = fln.AndroidNotificationDetails(
      'anchor_channel_v3',
      'Anchors V3',
      channelDescription: 'Daily anchor reminders',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
    );
    const notificationDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: fln.DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      888,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> scheduleNotificationAtExactTime({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      debugPrint('Warning: Scheduled time is in the past.');
      return;
    }

    final tzNow = tz.TZDateTime.now(tz.local);
    final duration = scheduledTime.difference(now);
    final tzScheduledDate = tzNow.add(duration);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'anchor_channel_v3',
            'Anchors V3',
            channelDescription: 'Daily anchor reminders',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.alarmClock,
      );
      debugPrint('Notification scheduled successfully.');
    } catch (error) {
      debugPrint('Error scheduling notification: $error');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'anchor_channel_v3',
            'Anchors V3',
            channelDescription: 'Daily anchor reminders',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: fln.DateTimeComponents.time,
      );
      debugPrint('Notification scheduled successfully.');
    } catch (error) {
      debugPrint('Error scheduling notification: $error');
      if (!error.toString().contains('exact_alarms_not_permitted')) {
        return;
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'anchor_channel_v3',
            'Anchors V3',
            channelDescription: 'Daily anchor reminders',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: fln.DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
