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
  int groupColorIndex; // 分组颜色索引：同一根源分解出来的计划使用相同的颜色
  String? reminderId; // 关联的 iOS 系统「提醒事项」唯一标识符 (calendarItemIdentifier)

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
    this.groupColorIndex = -1, // -1 表示无分组颜色
    this.reminderId,
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
      'groupColorIndex': groupColorIndex,
      'reminderId': reminderId,
    };
  }

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '未开始',
      createTime: json['createTime'] is int
          ? json['createTime'] as int
          : (int.tryParse(json['createTime']?.toString() ?? '') ??
              DateTime.now().millisecondsSinceEpoch),
      completeTime: json['completeTime'] is int
          ? json['completeTime'] as int
          : int.tryParse(json['completeTime']?.toString() ?? ''),
      aiTags: List<String>.from(json['aiTags'] ?? []),
      isExplored: json['isExplored'] == true,
      parentId: json['parentId']?.toString(),
      decompositionLevel: json['decompositionLevel'] is int
          ? json['decompositionLevel'] as int
          : (int.tryParse(json['decompositionLevel']?.toString() ?? '') ?? 0),
      groupColorIndex: json['groupColorIndex'] is int
          ? json['groupColorIndex'] as int
          : (int.tryParse(json['groupColorIndex']?.toString() ?? '') ?? -1),
      reminderId: json['reminderId']?.toString(),
    );
  }
}
