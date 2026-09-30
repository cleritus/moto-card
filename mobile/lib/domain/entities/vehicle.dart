import '../../core/utils/calendar_date.dart';

class Vehicle {
  final String id;
  final String userId;
  final String name;
  final String make;
  final String vehicleModel;
  final int year;
  final int? mileage;
  final String licensePlate;
  final String? vin;
  final DateTime? purchaseDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.name,
    required this.make,
    required this.vehicleModel,
    required this.year,
    this.mileage,
    required this.licensePlate,
    this.vin,
    this.purchaseDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        make: json['make'] as String,
        vehicleModel: json['vehicleModel'] as String,
        year: json['year'] as int,
        mileage: json['mileage'] as int?,
        // Falls back to empty for vehicles created before this field existed.
        licensePlate: json['licensePlate'] as String? ?? '',
        vin: json['vin'] as String?,
        purchaseDate: json['purchaseDate'] != null
            ? parseCalendarDate(json['purchaseDate'] as String)
            : null,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'userId': userId,
      'name': name,
      'make': make,
      'vehicleModel': vehicleModel,
      'year': year,
      'mileage': mileage,
      'licensePlate': licensePlate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    if (vin != null) map['vin'] = vin;
    if (purchaseDate != null) {
      map['purchaseDate'] = formatCalendarDate(purchaseDate!);
    }
    if (notes != null) map['notes'] = notes;
    return map;
  }

  Vehicle copyWith({
    String? id,
    String? userId,
    String? name,
    String? make,
    String? vehicleModel,
    int? year,
    int? mileage,
    String? licensePlate,
    String? vin,
    DateTime? purchaseDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Vehicle(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        make: make ?? this.make,
        vehicleModel: vehicleModel ?? this.vehicleModel,
        year: year ?? this.year,
        mileage: mileage ?? this.mileage,
        licensePlate: licensePlate ?? this.licensePlate,
        vin: vin ?? this.vin,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}