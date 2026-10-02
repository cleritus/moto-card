import 'package:dio/dio.dart';

import '../../config/constants.dart';
import '../exceptions/app_exception.dart';
import 'claude_models.dart';

/// Talks to Anthropic's own API directly with the user's own key.
///
/// Deliberately its OWN `Dio` instance, never `dioProvider` — that one is
/// wired for this app's own backend (JWT header, 401-refresh interceptor,
/// Moto-Card base URL), all of which is wrong for `api.anthropic.com`
/// (`x-api-key` auth, no refresh concept, different host). The app's
/// backend never sees this key; it never passes through `dioProvider`.
class ClaudeClient {
  final Dio _dio;

  ClaudeClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.claudeApiBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  Future<ClaudeResponse> sendMessage({
    required String apiKey,
    required String system,
    required List<ClaudeMessage> messages,
    required List<Map<String, dynamic>> tools,
  }) async {
    try {
      final response = await _dio.post(
        '/v1/messages',
        options: Options(headers: _headers(apiKey)),
        data: {
          'model': AppConstants.claudeModel,
          'max_tokens': 1024,
          'system': system,
          'messages': messages.map((m) => m.toJson()).toList(),
          'tools': tools,
          'tool_choice': {'type': 'auto'},
        },
      );
      return ClaudeResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// One cheap call to confirm the key is accepted before persisting it.
  /// Only a 401 counts as "invalid" — any other failure (network blip,
  /// 429) shouldn't block saving a key that might be perfectly fine.
  Future<bool> validateApiKey(String apiKey) async {
    try {
      await _dio.post(
        '/v1/messages',
        options: Options(headers: _headers(apiKey)),
        data: {
          'model': AppConstants.claudeModel,
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'hi'},
          ],
        },
      );
      return true;
    } on DioException catch (e) {
      return e.response?.statusCode != 401;
    }
  }

  Map<String, String> _headers(String apiKey) => {
        'x-api-key': apiKey,
        'anthropic-version': AppConstants.claudeApiVersion,
        'content-type': 'application/json',
      };

  AppException _handleError(DioException e) {
    final data = e.response?.data;
    final message =
        data is Map ? (data['error']?['message'] as String?) : null;
    return switch (e.response?.statusCode) {
      401 => AuthException(
          message: message ?? 'Nieprawidłowy klucz API Claude.'),
      429 => NetworkException(
          message: 'Za dużo zapytań do Claude, spróbuj za chwilę.'),
      _ => NetworkException(
          message: message ?? e.message ?? 'Błąd połączenia z Claude.'),
    };
  }
}
