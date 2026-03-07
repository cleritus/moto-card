class ServiceLog {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int mileage;
  final String serviceType;
  final String? description;
  final String? mechanic;
  final double totalCost;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.mileage,
    required this.serviceType,
    this.description,
    this.mechanic,
    required this.totalCost,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceLog.fromJson(Map<String, dynamic> json) => ServiceLog(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        date: DateTime.parse(json['date'] as String),
        mileage: json['mileage'] as int,
        serviceType: json['serviceType'] as String,
        description: json['description'] as String?,
        mechanic: json['mechanic'] as String?,
        totalCost: (json['totalCost'] as num).toDouble(),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'date': date.toIso8601String(),
        'mileage': mileage,
        'serviceType': serviceType,
        'description': description,
        'mechanic': mechanic,
        'totalCost': totalCost,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  ServiceLog copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    int? mileage,
    String? serviceType,
    String? description,
    String? mechanic,
    double? totalCost,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ServiceLog(
        id: id ?? this.id,
        vehicleId: vehicleId ?? this.vehicleId,
        date: date ?? this.date,
        mileage: mileage ?? this.mileage,
        serviceType: serviceType ?? this.serviceType,
        description: description ?? this.description,
        mechanic: mechanic ?? this.mechanic,
        totalCost: totalCost ?? this.totalCost,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}