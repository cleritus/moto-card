/// Hand-written request/response shapes for Anthropic's Messages API — no
/// freezed/json_serializable, matching the rest of this codebase's
/// convention of manual fromJson/toJson despite both being in pubspec.yaml.

class ClaudeContentBlock {
  final String type; // 'text' | 'tool_use' | 'tool_result' | 'thinking' | 'redacted_thinking'
  final String? text;

  /// For 'tool_use': this block's own id. For 'tool_result': the tool_use
  /// id it answers.
  final String? toolUseId;
  final String? toolName;
  final Map<String, dynamic>? toolInput;
  final String? toolResultContent;
  final bool? isError;

  /// Extended-thinking blocks (Sonnet 5 emits these even without the
  /// `thinking` request param set) — `thinking`/`signature` for a normal
  /// block, `redactedData` for a `redacted_thinking` block. Must round-trip
  /// byte-for-byte or Anthropic rejects the replay on the NEXT call with
  /// `messages.N.content.0.thinking.thinking: Field required`.
  final String? thinking;
  final String? signature;
  final String? redactedData;

  const ClaudeContentBlock({
    required this.type,
    this.text,
    this.toolUseId,
    this.toolName,
    this.toolInput,
    this.toolResultContent,
    this.isError,
    this.thinking,
    this.signature,
    this.redactedData,
  });

  factory ClaudeContentBlock.fromJson(Map<String, dynamic> json) {
    return ClaudeContentBlock(
      type: json['type'] as String,
      text: json['text'] as String?,
      toolUseId: json['id'] as String?,
      toolName: json['name'] as String?,
      toolInput: json['input'] as Map<String, dynamic>?,
      thinking: json['thinking'] as String?,
      signature: json['signature'] as String?,
      redactedData: json['data'] as String?,
    );
  }

  factory ClaudeContentBlock.textBlock(String value) =>
      ClaudeContentBlock(type: 'text', text: value);

  factory ClaudeContentBlock.toolResult({
    required String toolUseId,
    required String content,
    bool isError = false,
  }) =>
      ClaudeContentBlock(
        type: 'tool_result',
        toolUseId: toolUseId,
        toolResultContent: content,
        isError: isError,
      );

  /// Must round-trip 'tool_use' blocks exactly as Claude sent them — the
  /// orchestrator replays the whole assistant turn back as history, and a
  /// reshaped/stripped tool_use block breaks that replay.
  Map<String, dynamic> toJson() {
    switch (type) {
      case 'text':
        return {'type': 'text', 'text': text};
      case 'tool_use':
        return {
          'type': 'tool_use',
          'id': toolUseId,
          'name': toolName,
          'input': toolInput,
        };
      case 'tool_result':
        return {
          'type': 'tool_result',
          'tool_use_id': toolUseId,
          'content': toolResultContent,
          if (isError == true) 'is_error': true,
        };
      case 'thinking':
        return {
          'type': 'thinking',
          'thinking': thinking,
          'signature': signature,
        };
      case 'redacted_thinking':
        return {'type': 'redacted_thinking', 'data': redactedData};
      default:
        return {'type': type};
    }
  }
}

class ClaudeMessage {
  final String role; // 'user' | 'assistant'
  final List<ClaudeContentBlock> content;

  const ClaudeMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content.map((c) => c.toJson()).toList(),
      };
}

class ClaudeResponse {
  final List<ClaudeContentBlock> content;
  final String stopReason;

  const ClaudeResponse({required this.content, required this.stopReason});

  factory ClaudeResponse.fromJson(Map<String, dynamic> json) {
    final blocks = (json['content'] as List)
        .map((b) => ClaudeContentBlock.fromJson(b as Map<String, dynamic>))
        .toList();
    return ClaudeResponse(
      content: blocks,
      stopReason: json['stop_reason'] as String? ?? 'end_turn',
    );
  }
}
