enum ReminderType { date, mileage }

enum ReminderFilter { active, completed, all }

class Reminder {
  final String id;
  final String vehicleId;
  final String title;
  final ReminderType type;
  final DateTime? dueDate;
  final int? dueMileage;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.type,
    this.dueDate,
    this.dueMileage,
    required this.isCompleted,
    this.completedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        title: json['title'] as String,
        type: ReminderType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ReminderType.date,
        ),
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
        dueMileage: json['dueMileage'] as int?,
        isCompleted: json['isCompleted'] as bool,
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'title': title,
        'type': type.name,
        'dueDate': dueDate?.toIso8601String(),
        'dueMileage': dueMileage,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Reminder copyWith({
    String? id,
    String? vehicleId,
    String? title,
    ReminderType? type,
    DateTime? dueDate,
    int? dueMileage,
    bool? isCompleted,
    DateTime? completedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Reminder(
        id: id ?? this.id,
        vehicleId: vehicleId ?? this.vehicleId,
        title: title ?? this.title,
        type: type ?? this.type,
        dueDate: dueDate ?? this.dueDate,
        dueMileage: dueMileage ?? this.dueMileage,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt ?? this.completedAt,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}