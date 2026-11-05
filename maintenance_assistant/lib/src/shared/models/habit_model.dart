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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '进行中',
      createTime: json['createTime'] is int
          ? json['createTime'] as int
          : (int.tryParse(json['createTime']?.toString() ?? '') ??
              DateTime.now().millisecondsSinceEpoch),
      totalDays: json['totalDays'] is int
          ? json['totalDays'] as int
          : (int.tryParse(json['totalDays']?.toString() ?? '') ?? 0),
      completionHistory: (json['completionHistory'] as List<dynamic>?)
              ?.map((e) => e is int ? e : (int.tryParse(e.toString()) ?? 0))
              .where((e) => e > 0)
              .toList() ??
          [],
    );
  }
}
