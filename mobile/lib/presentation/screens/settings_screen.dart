import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../providers/ai_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_app_bar.dart';
import '../widgets/garage_button.dart';
import '../widgets/labeled_field.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyController = TextEditingController();
  bool _obscured = true;
  bool _isSaving = false;

  /// Reveals the key input even when a key is already saved — otherwise an
  /// empty "paste a key" box sitting right next to "key connected" reads as
  /// if the save failed.
  bool _editing = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;
    setState(() => _isSaving = true);
    final ok = await ref.read(aiSettingsProvider.notifier).saveKey(key);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      _keyController.clear();
      setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiSettingsProvider);
    final showInput = _editing || !state.hasKey;

    return Scaffold(
      appBar: const GarageAppBar(title: 'USTAWIENIA'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppGeo.screenMargin,
            24,
            AppGeo.screenMargin,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FormSection(title: 'ASYSTENT AI', code: 'SEKCJA 1'),
              Text(
                state.hasKey
                    ? 'Klucz Claude podłączony. Asystent gotowy do rozmowy.'
                    : 'Podłącz własny klucz API Claude (console.anthropic.com), '
                        'żeby rozmawiać z asystentem o swoich danych — '
                        'tankowaniach, serwisach, przypomnieniach. Klucz zostaje '
                        'tylko na tym urządzeniu, appka go nigdzie nie wysyła '
                        'poza bezpośrednim połączeniem z Anthropic.',
                style: AppText.body(color: AppColors.fadedInk),
              ),
              if (showInput) ...[
                LabeledField(
                  label: 'KLUCZ API',
                  child: TextField(
                    controller: _keyController,
                    obscureText: _obscured,
                    style: AppText.data(size: 14.5),
                    decoration: InputDecoration(
                      hintText: 'sk-ant-...',
                      suffixIcon: RevealToggle(
                        obscured: _obscured,
                        onTap: () => setState(() => _obscured = !_obscured),
                      ),
                    ),
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  FaultStrip(message: state.errorMessage!),
                ],
                const SizedBox(height: 20),
                GarageButton(
                  label: 'ZAPISZ KLUCZ',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
                if (state.hasKey) ...[
                  const SizedBox(height: 14),
                  GarageButton.ghost(
                    label: 'ANULUJ',
                    onPressed: () {
                      _keyController.clear();
                      setState(() => _editing = false);
                    },
                  ),
                ],
              ] else ...[
                const SizedBox(height: 20),
                GarageButton.ghost(
                  label: 'ZMIEŃ KLUCZ',
                  onPressed: () => setState(() => _editing = true),
                ),
                const SizedBox(height: 14),
                GarageButton.danger(
                  label: 'USUŃ KLUCZ',
                  onPressed: () => ref.read(aiSettingsProvider.notifier).clearKey(),
                ),
              ],
              const FormSection(title: 'KONTO', code: 'SEKCJA 2'),
              const SizedBox(height: 20),
              GarageButton.ghost(
                label: 'WYLOGUJ',
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
