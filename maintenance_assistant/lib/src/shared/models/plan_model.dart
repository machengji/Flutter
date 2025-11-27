class Plan {
  final String id;
  final String name;
  String status;
  final int createTime;
  int? completeTime;
  List<String> aiTags;
  bool isExplored;

  Plan({
    required this.id,
    required this.name,
    this.status = '未开始',
    required this.createTime,
    this.completeTime,
    this.aiTags = const [],
    this.isExplored = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'createTime': createTime,
      'completeTime': completeTime,
      'aiTags': aiTags,
      'isExplored': isExplored,
    };
  }

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'].toString(),
      name: json['name'],
      status: json['status'] ?? '未开始',
      createTime: json['createTime'],
      completeTime: json['completeTime'],
      aiTags: List<String>.from(json['aiTags'] ?? []),
      isExplored: json['isExplored'] ?? false,
    );
  }
}
