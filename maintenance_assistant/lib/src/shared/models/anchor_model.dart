class Anchor {
  final String id;
  String name;
  String time; // Format: HH:mm
  List<String> planIds;
  List<String> habitIds;
  bool isReminderEnabled;
  bool isCalendarSynced;

  /// 重复周期模式：
  /// - 'daily': 每天（周一至周日）
  /// - 'workdays': 工作日（周一至周五）
  /// - 'weekends': 休息日（周六、周日）
  /// - 'custom': 自定义星期（由 customDays 指定 1=周一 ... 7=周日）
  String repeatMode;
  List<int> customDays;

  Anchor({
    required this.id,
    required this.name,
    required this.time,
    List<String>? planIds,
    List<String>? habitIds,
    this.isReminderEnabled = true,
    this.isCalendarSynced = false,
    this.repeatMode = 'daily',
    List<int>? customDays,
  }) : planIds = planIds != null ? List<String>.from(planIds) : <String>[],
       habitIds = habitIds != null ? List<String>.from(habitIds) : <String>[],
       customDays = customDays != null
           ? List<int>.from(customDays)
           : <int>[1, 2, 3, 4, 5, 6, 7];

  /// 获取该锚点实际生效的星期列表（1=周一 ... 7=周日）
  List<int> get effectiveDays {
    switch (repeatMode) {
      case 'workdays':
        return const [1, 2, 3, 4, 5];
      case 'weekends':
        return const [6, 7];
      case 'custom':
        final sorted = customDays.where((d) => d >= 1 && d <= 7).toSet().toList()
          ..sort();
        return sorted.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : sorted;
      case 'daily':
      default:
        return const [1, 2, 3, 4, 5, 6, 7];
    }
  }

  /// 获取人类可读的重复周期标签（如：每天 / 工作日 / 休息日 / 周一、三、五）
  String get repeatLabel {
    switch (repeatMode) {
      case 'workdays':
        return '工作日';
      case 'weekends':
        return '休息日';
      case 'custom':
        final days = effectiveDays;
        if (days.length == 7) return '每天';
        if (days.length == 5 &&
            days.contains(1) &&
            days.contains(2) &&
            days.contains(3) &&
            days.contains(4) &&
            days.contains(5)) {
          return '工作日';
        }
        if (days.length == 2 && days.contains(6) && days.contains(7)) {
          return '休息日';
        }
        const dayNames = ['', '一', '二', '三', '四', '五', '六', '日'];
        return '周${days.map((d) => dayNames[d]).join('、')}';
      case 'daily':
      default:
        return '每天';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'planIds': planIds,
      'habitIds': habitIds,
      'isReminderEnabled': isReminderEnabled,
      'isCalendarSynced': isCalendarSynced,
      'repeatMode': repeatMode,
      'customDays': customDays,
    };
  }

  factory Anchor.fromJson(Map<String, dynamic> json) {
    final parsedCustomDays = (json['customDays'] as List<dynamic>?)
            ?.map((e) => int.tryParse(e.toString()) ?? 0)
            .where((d) => d >= 1 && d <= 7)
            .toList() ??
        [1, 2, 3, 4, 5, 6, 7];

    final reminderEnabled = json.containsKey('isReminderEnabled')
        ? (json['isReminderEnabled'] == true)
        : true;

    return Anchor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      time: json['time']?.toString() ?? '00:00',
      planIds: (json['planIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      habitIds: (json['habitIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isReminderEnabled: reminderEnabled,
      isCalendarSynced: json['isCalendarSynced'] == true,
      repeatMode: json['repeatMode']?.toString() ?? 'daily',
      customDays: parsedCustomDays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : parsedCustomDays,
    );
  }
}
