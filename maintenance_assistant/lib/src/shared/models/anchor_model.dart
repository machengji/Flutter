class Anchor {
  final String id;
  String name;
  String time; // Format: HH:mm
  List<String> planIds;
  List<String> habitIds;

  Anchor({
    required this.id,
    required this.name,
    required this.time,
    List<String>? planIds,
    List<String>? habitIds,
  }) : planIds = planIds ?? [],
       habitIds = habitIds ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'planIds': planIds,
      'habitIds': habitIds,
    };
  }

  factory Anchor.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
