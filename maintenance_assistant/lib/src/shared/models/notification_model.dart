class NotificationModel {
  final String id;
  final String title;
  final String body;
  final int timestamp;
  bool isRead;
  bool isDeleted;
  final String? relatedId; // e.g., anchor ID
  final String type; // 'anchor', 'system', etc.

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.isDeleted = false,
    this.relatedId,
    this.type = 'system',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'isRead': isRead,
      'isDeleted': isDeleted,
      'relatedId': relatedId,
      'type': type,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      timestamp: json['timestamp'],
      isRead: json['isRead'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      relatedId: json['relatedId']?.toString(),
      type: json['type'] ?? 'system',
    );
  }
}
