class Plan {
  final String id;
  String name;
  String status;
  final int createTime;
  int? completeTime;
  List<String> aiTags;
  bool isExplored;
  String? parentId; // 父计划ID，用于标识由AI分解出来的子计划
  int decompositionLevel; // 分解层级：0=原始计划，1=第一次分解，2=第二次分解...

  Plan({
    required this.id,
    required this.name,
    this.status = '未开始',
    required this.createTime,
    this.completeTime,
    this.aiTags = const [],
    this.isExplored = false,
    this.parentId,
    this.decompositionLevel = 0,
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
      'parentId': parentId,
      'decompositionLevel': decompositionLevel,
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
      parentId: json['parentId'],
      decompositionLevel: json['decompositionLevel'] ?? json['groupColorIndex'] ?? 0,
    );
  }
}
