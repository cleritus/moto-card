class Vehicle {
  final String id;
  final String userId;
  final String brand;
  final String model;
  final int year;
  final String? licensePlate;
  final String? vin;
  final int mileage;
  final DateTime? purchaseDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.year,
    this.licensePlate,
    this.vin,
    required this.mileage,
    this.purchaseDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        userId: json['userId'] as String,
        brand: json['brand'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        licensePlate: json['licensePlate'] as String?,
        vin: json['vin'] as String?,
        mileage: json['mileage'] as int,
        purchaseDate: json['purchaseDate'] != null
            ? DateTime.parse(json['purchaseDate'] as String)
            : null,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'brand': brand,
        'model': model,
        'year': year,
        'licensePlate': licensePlate,
        'vin': vin,
        'mileage': mileage,
        'purchaseDate': purchaseDate?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
