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
      id: json['id'].toString(),
      name: json['name'],
      time: json['time'],
      planIds: List<String>.from(json['planIds'] ?? []),
      habitIds: List<String>.from(json['habitIds'] ?? []),
    );
  }
}
