import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // Web build: API address comes from `--dart-define=API_BASE=https://...`.
  static const String _webApiBase =
      String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:3000/api');

  // API — physical Android phone reaches the dev PC over LAN (swap back to
  // 10.0.2.2 for the emulator); desktop/iOS use localhost.
  static String get baseUrl => kIsWeb
      ? _webApiBase
      : Platform.isAndroid
          ? 'http://192.168.0.25:3000/api'
          : 'http://localhost:3000/api';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
  static const String claudeApiKeyKey = 'claude_api_key';

  // AI bridge (Claude) — user's own key, called directly from the device,
  // never through this app's own backend/baseUrl above.
  static const String claudeApiBaseUrl = 'https://api.anthropic.com';
  static const String claudeApiVersion = '2023-06-01';
  static const String claudeModel = 'claude-sonnet-5';
  static const int aiMaxToolLoopIterations = 6;

  // Pagination
  static const int defaultPageSize = 20;

  // Date formats
  static const String dateFormat = 'dd.MM.yyyy';
  static const String dateTimeFormat = 'dd.MM.yyyy HH:mm';
}
