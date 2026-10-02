import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/tool_executor.dart';
import '../../core/ai/tool_loop_orchestrator.dart';
import 'providers.dart';

enum AiChatRole { user, assistant, error }

class AiChatMessage {
  final AiChatRole role;
  final String text;

  const AiChatMessage({required this.role, required this.text});
}

enum AiAssistantStatus { idle, sending, error }

class AiAssistantState {
  final AiAssistantStatus status;
  final List<AiChatMessage> messages;

  /// Set while an edit/delete waits for the user's OK; the screen shows the
  /// confirmation dialog for it.
  final AiActionPreview? pendingAction;

  const AiAssistantState({
    this.status = AiAssistantStatus.idle,
    this.messages = const [],
    this.pendingAction,
  });

  AiAssistantState copyWith({
    AiAssistantStatus? status,
    List<AiChatMessage>? messages,
    AiActionPreview? pendingAction,
    bool clearPendingAction = false,
  }) =>
      AiAssistantState(
        status: status ?? this.status,
        messages: messages ?? this.messages,
        pendingAction:
            clearPendingAction ? null : (pendingAction ?? this.pendingAction),
      );
}

/// Ephemeral per-screen chat — no persistence in v1. One [AiOrchestrator]
/// (and so one Claude conversation) lives for as long as this screen does;
/// reopening the assistant starts fresh.
class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final Ref _ref;
  AiOrchestrator? _orchestrator;
  Completer<bool>? _pendingConfirmation;

  AiAssistantNotifier(this._ref) : super(const AiAssistantState());

  Future<bool> _requestConfirmation(AiActionPreview preview) {
    _pendingConfirmation?.complete(false);
    final completer = Completer<bool>();
    _pendingConfirmation = completer;
    state = state.copyWith(pendingAction: preview);
    return completer.future;
  }

  /// Called by the screen with the user's answer to the dialog.
  void resolveConfirmation(bool approved) {
    final completer = _pendingConfirmation;
    if (completer == null || completer.isCompleted) return;
    _pendingConfirmation = null;
    state = state.copyWith(clearPendingAction: true);
    completer.complete(approved);
  }

  @override
  void dispose() {
    // Leaving the screen mid-question counts as "no".
    final completer = _pendingConfirmation;
    if (completer != null && !completer.isCompleted) completer.complete(false);
    super.dispose();
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;

    state = state.copyWith(
      status: AiAssistantStatus.sending,
      messages: [
        ...state.messages,
        AiChatMessage(role: AiChatRole.user, text: text),
      ],
    );

    final orchestrator = await _ensureOrchestrator();
    if (orchestrator == null) {
      state = state.copyWith(
        status: AiAssistantStatus.error,
        messages: [
          ...state.messages,
          const AiChatMessage(
            role: AiChatRole.error,
            text: 'Brak skonfigurowanego klucza API — przejdź do Ustawień.',
          ),
        ],
      );
      return;
    }

    final result = await orchestrator.send(text);
    if (!mounted) return;
    if (result.status == AiTurnStatus.done) {
      state = state.copyWith(
        status: AiAssistantStatus.idle,
        messages: [
          ...state.messages,
          AiChatMessage(role: AiChatRole.assistant, text: result.text!),
        ],
      );
    } else {
      state = state.copyWith(
        status: AiAssistantStatus.error,
        messages: [
          ...state.messages,
          AiChatMessage(
            role: AiChatRole.error,
            text: result.errorMessage ?? 'Wystąpił błąd.',
          ),
        ],
      );
    }
  }

  Future<AiOrchestrator?> _ensureOrchestrator() async {
    if (_orchestrator != null) return _orchestrator;
    final apiKey = await _ref.read(aiSettingsRepositoryProvider).getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;
    _orchestrator = AiOrchestrator(
      client: _ref.read(claudeClientProvider),
      executor: _ref.read(aiToolExecutorProvider),
      apiKey: apiKey,
      confirm: _requestConfirmation,
    );
    return _orchestrator;
  }
}

final aiAssistantProvider =
    StateNotifierProvider.autoDispose<AiAssistantNotifier, AiAssistantState>(
  (ref) => AiAssistantNotifier(ref),
);
