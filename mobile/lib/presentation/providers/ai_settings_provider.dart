import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

enum AiSettingsStatus { initial, loading, ready }

class AiSettingsState {
  final AiSettingsStatus status;
  final bool hasKey;
  final String? errorMessage;

  const AiSettingsState({
    this.status = AiSettingsStatus.initial,
    this.hasKey = false,
    this.errorMessage,
  });

  AiSettingsState copyWith({
    AiSettingsStatus? status,
    bool? hasKey,
    String? errorMessage,
  }) =>
      AiSettingsState(
        status: status ?? this.status,
        hasKey: hasKey ?? this.hasKey,
        errorMessage: errorMessage,
      );
}

class AiSettingsNotifier extends StateNotifier<AiSettingsState> {
  final Ref _ref;

  AiSettingsNotifier(this._ref) : super(const AiSettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final hasKey = await _ref.read(aiSettingsRepositoryProvider).hasApiKey();
    state = state.copyWith(status: AiSettingsStatus.ready, hasKey: hasKey);
  }

  Future<bool> saveKey(String apiKey) async {
    state = state.copyWith(status: AiSettingsStatus.loading, errorMessage: null);
    final ok =
        await _ref.read(aiSettingsRepositoryProvider).validateAndSaveApiKey(apiKey);
    state = state.copyWith(
      status: AiSettingsStatus.ready,
      hasKey: ok,
      errorMessage: ok ? null : 'Nieprawidłowy klucz API.',
    );
    return ok;
  }

  Future<void> clearKey() async {
    await _ref.read(aiSettingsRepositoryProvider).clearApiKey();
    state = state.copyWith(hasKey: false);
  }
}

final aiSettingsProvider =
    StateNotifierProvider<AiSettingsNotifier, AiSettingsState>(
  (ref) => AiSettingsNotifier(ref),
);
