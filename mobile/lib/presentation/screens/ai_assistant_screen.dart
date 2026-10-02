import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../providers/ai_assistant_provider.dart';
import '../providers/ai_settings_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/garage_app_bar.dart';
import '../widgets/garage_button.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    ref.read(aiAssistantProvider.notifier).send(text);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aiSettingsProvider);
    final chat = ref.watch(aiAssistantProvider);

    ref.listen<AiAssistantState>(aiAssistantProvider, (previous, next) {
      if (next.messages.length != (previous?.messages.length ?? 0)) {
        _scrollToEnd();
      }
    });

    if (!settings.hasKey) {
      return Scaffold(
        appBar: const GarageAppBar(title: 'ASYSTENT AI'),
        body: SafeArea(
          child: Column(
            children: [
              const Expanded(
                child: EmptyState(
                  tag: 'BRAK KLUCZA',
                  title: 'ASYSTENT WYŁĄCZONY.',
                  subtitle:
                      'Podłącz własny klucz API Claude w Ustawieniach, żeby '
                      'zacząć rozmowę.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppGeo.screenMargin,
                  0,
                  AppGeo.screenMargin,
                  24,
                ),
                child: GarageButton(
                  label: 'PRZEJDŹ DO USTAWIEŃ',
                  onPressed: () => context.push('/settings'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const GarageAppBar(title: 'ASYSTENT AI'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chat.messages.isEmpty
                  ? const EmptyState(
                      tag: 'NOWA ROZMOWA',
                      title: 'O CO SPYTAĆ?',
                      subtitle:
                          'Np. "jakie mam pojazdy?" albo "dodaj tankowanie '
                          '40 litrów za 280 zł przy 50000 km".',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppGeo.screenMargin,
                        16,
                        AppGeo.screenMargin,
                        16,
                      ),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) =>
                          _ChatBubble(message: chat.messages[index]),
                    ),
            ),
            if (chat.status == AiAssistantStatus.sending)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('CLAUDE PISZE…', style: AppText.micro()),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppGeo.screenMargin,
                0,
                AppGeo.screenMargin,
                16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: AppText.body(size: 14.5),
                      decoration: const InputDecoration(
                        hintText: 'Napisz wiadomość...',
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: chat.status == AiAssistantStatus.sending ? null : _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.oxideOrange,
                        border: Border.all(color: AppColors.bone, width: 1.5),
                      ),
                      child: Text(
                        '→',
                        style:
                            AppText.button(size: 20, color: AppColors.grease),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiChatRole.user;
    final isError = message.role == AiChatRole.error;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? AppColors.grease : Colors.transparent,
          border: Border.all(
            color: isError ? AppColors.oxideLit : AppColors.steel,
            width: 1.5,
          ),
        ),
        child: Text(
          message.text,
          style: AppText.body(
            size: 13.5,
            color: isError ? AppColors.oxideLit : AppColors.agedPaper,
          ),
        ),
      ),
    );
  }
}
