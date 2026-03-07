class FuelLog {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int mileage;
  final double fuelAmount;
  final double totalCost;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FuelLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.mileage,
    required this.fuelAmount,
    required this.totalCost,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FuelLog.fromJson(Map<String, dynamic> json) => FuelLog(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        date: DateTime.parse(json['date'] as String),
        mileage: json['mileage'] as int,
        fuelAmount: (json['fuelAmount'] as num).toDouble(),
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
        'fuelAmount': fuelAmount,
        'totalCost': totalCost,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  FuelLog copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    int? mileage,
    double? fuelAmount,
    double? totalCost,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      FuelLog(
        id: id ?? this.id,
        vehicleId: vehicleId ?? this.vehicleId,
        date: date ?? this.date,
        mileage: mileage ?? this.mileage,
        fuelAmount: fuelAmount ?? this.fuelAmount,
        totalCost: totalCost ?? this.totalCost,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}