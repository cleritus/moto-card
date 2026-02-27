class User {
  final String id;
  final String email;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'createdAt': createdAt?.toIso8601String(),
      };
}
