import 'user.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User? user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>;

    return AuthResponse(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
      user: data['user'] != null
          ? User.fromJson(data['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'data': {
          if (user != null) 'user': user!.toJson(),
          'tokens': {
            'accessToken': accessToken,
            'refreshToken': refreshToken,
          }
        }
      };

  AuthResponse copyWith({
    String? accessToken,
    String? refreshToken,
    User? user,
  }) =>
      AuthResponse(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        user: user ?? this.user,
      );
}