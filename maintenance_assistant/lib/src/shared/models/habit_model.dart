class Habit {
  final String id;
  String name;
  String status;
  final int createTime;
  int totalDays;
  List<int> completionHistory; // List of timestamps

  Habit({
    required this.id,
    required this.name,
    this.status = '进行中',
    required this.createTime,
    this.totalDays = 0,
    this.completionHistory = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'createTime': createTime,
      'totalDays': totalDays,
      'completionHistory': completionHistory,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'].toString(),
      name: json['name'],
      status: json['status'] ?? '进行中',
      createTime: json['createTime'],
      totalDays: json['totalDays'] ?? 0,
      completionHistory: List<int>.from(json['completionHistory'] ?? []),
    );
  }
}
