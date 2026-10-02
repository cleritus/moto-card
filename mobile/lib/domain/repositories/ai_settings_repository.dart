abstract class AiSettingsRepository {
  Future<String?> getApiKey();
  Future<bool> hasApiKey();

  /// Validates the key against Anthropic before persisting it. Returns
  /// false (without saving) if the key is rejected.
  Future<bool> validateAndSaveApiKey(String apiKey);
  Future<void> clearApiKey();
}
