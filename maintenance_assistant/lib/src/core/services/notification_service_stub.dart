import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> init() async {}

  Future<void> showInstantNotification({
    String title = '',
    String body = '',
  }) async {}

  Future<void> scheduleNotificationAtExactTime({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {}

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {}

  Future<void> cancelNotification(int id) async {}
}
