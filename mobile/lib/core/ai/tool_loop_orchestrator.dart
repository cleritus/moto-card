import '../../config/constants.dart';
import '../exceptions/app_exception.dart';
import 'claude_client.dart';
import 'claude_models.dart';
import 'system_prompt.dart';
import 'tool_definitions.dart';
import 'tool_executor.dart';

enum AiTurnStatus { done, error }

class AiTurnResult {
  final AiTurnStatus status;
  final String? text;
  final String? errorMessage;

  const AiTurnResult({required this.status, this.text, this.errorMessage});
}

/// The tool-calling loop: send -> tool_use? -> execute via [AiToolExecutor]
/// -> tool_result -> send again -> ... -> end_turn.
///
/// One instance per chat session — `_messages` accumulates the whole
/// conversation so Claude keeps context turn to turn. No confirmation
/// gating yet (Phase 3); every tool call here executes immediately.
class AiOrchestrator {
  final ClaudeClient _client;
  final AiToolExecutor _executor;
  final String _apiKey;
  final List<ClaudeMessage> _messages = [];

  AiOrchestrator({
    required ClaudeClient client,
    required AiToolExecutor executor,
    required String apiKey,
  })  : _client = client,
        _executor = executor,
        _apiKey = apiKey;

  Future<AiTurnResult> send(String userText) async {
    _messages.add(ClaudeMessage(
      role: 'user',
      content: [ClaudeContentBlock.textBlock(userText)],
    ));

    for (var i = 0; i < AppConstants.aiMaxToolLoopIterations; i++) {
      final ClaudeResponse response;
      try {
        response = await _client.sendMessage(
          apiKey: _apiKey,
          system: buildAiSystemPrompt(),
          messages: _messages,
          tools: kAiTools,
        );
      } on AppException catch (e) {
        return AiTurnResult(status: AiTurnStatus.error, errorMessage: e.message);
      }

      _messages.add(ClaudeMessage(role: 'assistant', content: response.content));

      if (response.stopReason != 'tool_use') {
        final text = response.content
            .where((b) => b.type == 'text')
            .map((b) => b.text ?? '')
            .join('\n')
            .trim();
        return AiTurnResult(
          status: AiTurnStatus.done,
          text: text.isEmpty ? 'OK.' : text,
        );
      }

      final toolUseBlocks =
          response.content.where((b) => b.type == 'tool_use').toList();
      final results = <ClaudeContentBlock>[];
      for (final block in toolUseBlocks) {
        try {
          final result =
              await _executor.execute(block.toolName!, block.toolInput ?? {});
          results.add(ClaudeContentBlock.toolResult(
            toolUseId: block.toolUseId!,
            content: result,
          ));
        } on AppException catch (e) {
          results.add(ClaudeContentBlock.toolResult(
            toolUseId: block.toolUseId!,
            content: e.message,
            isError: true,
          ));
        }
      }
      // All tool_results for this turn go in ONE user message — splitting
      // them across messages silently trains the model to stop batching
      // parallel tool calls.
      _messages.add(ClaudeMessage(role: 'user', content: results));
    }

    return const AiTurnResult(
      status: AiTurnStatus.error,
      errorMessage: 'Zbyt wiele kroków — spróbuj doprecyzować prośbę.',
    );
  }
}
