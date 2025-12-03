import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

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
    } catch (e) {
      print('Error setting local location: $e');
    }

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    final fln.DarwinInitializationSettings initializationSettingsIOS =
        fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final fln.InitializationSettings initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse details) async {
        // Handle notification tap
      },
    );

    // Create the notification channel
    const fln.AndroidNotificationChannel channel = fln.AndroidNotificationChannel(
      'anchor_channel_v3', // id
      'Anchors V3', // title
      description: 'Daily anchor reminders', // description
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
    final fln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>();

    final bool? grantedNotification = await androidImplementation?.requestNotificationsPermission();
    final bool? grantedAlarm = await androidImplementation?.requestExactAlarmsPermission();
    
    // Request Battery Optimization Ignore
    final status = await Permission.ignoreBatteryOptimizations.request();
    
    print('Permission Status:');
    print('  Notifications: $grantedNotification');
    print('  Exact Alarms: $grantedAlarm');
    print('  Battery Optimization: $status');
  }

  Future<void> showInstantNotification({
    String title = '测试通知',
    String body = '这是一条立即发送的测试通知',
  }) async {
    const fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
        fln.AndroidNotificationDetails(
      'anchor_channel_v2',
      'Anchors',
      channelDescription: 'Daily anchor reminders',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
    );
    const fln.NotificationDetails platformChannelSpecifics =
        fln.NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      888,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Schedule notification at exact DateTime (including seconds)
  Future<void> scheduleNotificationAtExactTime({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final now = DateTime.now();
    
    if (scheduledTime.isBefore(now)) {
      print('Warning: Scheduled time is in the past!');
      return;
    }
    
    // Convert to TZDateTime for the plugin
    // Use TZDateTime.now(tz.local) to ensure we are in the correct timezone frame
    final tzNow = tz.TZDateTime.now(tz.local);
    final duration = scheduledTime.difference(now);
    final tzScheduledDate = tzNow.add(duration);
    
    print('Scheduling notification for ID: $id');
    print('  Current Time: $now');
    print('  Scheduled Time: $scheduledTime');
    print('  TZ Now: $tzNow');
    print('  TZ Scheduled Time: $tzScheduledDate');
    print('  Delay: ${duration.inSeconds} seconds');
    
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'anchor_channel_v3', // Changed channel ID
            'Anchors V3',
            channelDescription: 'Daily anchor reminders',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.alarmClock, // Changed to alarmClock
      );
      print('✅ Notification scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
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
    
    // Convert to TZDateTime for the plugin
    // This handles the conversion from Device Local Time -> Target Timezone (tz.local) correctly
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    
    print('Scheduling notification for ID: $id');
    print('  Device Time: $scheduledDate');
    print('  TZ Time: $tzScheduledDate');
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'anchor_channel_v2',
            'Anchors',
            channelDescription: 'Daily anchor reminders',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: fln.DateTimeComponents.time,
      );
      print('Notification scheduled successfully');
    } catch (e) {
      print('Error scheduling notification: $e');
      if (e.toString().contains('exact_alarms_not_permitted')) {
        print('Falling back to inexact notification');
        // Fallback to inexact notification
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          const fln.NotificationDetails(
            android: fln.AndroidNotificationDetails(
              'anchor_channel_v2',
              'Anchors',
              channelDescription: 'Daily anchor reminders',
              importance: fln.Importance.max,
              priority: fln.Priority.high,
            ),
            iOS: fln.DarwinNotificationDetails(),
          ),
          androidScheduleMode: fln.AndroidScheduleMode.alarmClock,
          matchDateTimeComponents: fln.DateTimeComponents.time,
        );
        print('Inexact notification scheduled successfully');
      }
    }
  }





  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
