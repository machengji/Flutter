import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_assistant/src/shared/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('should support JSON serialization', () {
      final notification = NotificationModel(
        id: '123',
        title: 'Test',
        body: 'Body',
        timestamp: 1000,
        isRead: true,
        relatedId: 'anchor_1',
        type: 'anchor',
      );

      final json = notification.toJson();
      expect(json['id'], '123');
      expect(json['title'], 'Test');
      expect(json['isRead'], true);

      final fromJson = NotificationModel.fromJson(json);
      expect(fromJson.id, notification.id);
      expect(fromJson.title, notification.title);
      expect(fromJson.isRead, notification.isRead);
    });

    test('should have default values', () {
      final json = {
        'id': '123',
        'title': 'Test',
        'body': 'Body',
        'timestamp': 1000,
      };

      final notification = NotificationModel.fromJson(json);
      expect(notification.isRead, false);
      expect(notification.type, 'system');
    });
  });
}
