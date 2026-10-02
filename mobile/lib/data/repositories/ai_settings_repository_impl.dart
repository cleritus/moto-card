import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/constants.dart';
import '../../core/ai/claude_client.dart';
import '../../domain/repositories/ai_settings_repository.dart';

class AiSettingsRepositoryImpl implements AiSettingsRepository {
  final FlutterSecureStorage _storage;
  final ClaudeClient _client;

  AiSettingsRepositoryImpl({
    required FlutterSecureStorage storage,
    required ClaudeClient client,
  })  : _storage = storage,
        _client = client;

  @override
  Future<String?> getApiKey() =>
      _storage.read(key: AppConstants.claudeApiKeyKey);

  @override
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  @override
  Future<bool> validateAndSaveApiKey(String apiKey) async {
    final valid = await _client.validateApiKey(apiKey);
    if (valid) {
      await _storage.write(key: AppConstants.claudeApiKeyKey, value: apiKey);
    }
    return valid;
  }

  @override
  Future<void> clearApiKey() => _storage.delete(key: AppConstants.claudeApiKeyKey);
}
