class Vehicle {
  final String id;
  final String userId;
  final String name;
  final String make;
  final String vehicleModel;
  final int year;
  final int? mileage;
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
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'make': make,
        'vehicleModel': vehicleModel,
        'year': year,
        'mileage': mileage,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Vehicle copyWith({
    String? id,
    String? userId,
    String? name,
    String? make,
    String? vehicleModel,
    int? year,
    int? mileage,
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
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}