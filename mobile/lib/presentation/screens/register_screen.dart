import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/double_rule.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_button.dart';
import '../widgets/labeled_field.dart';

/// §6 row 1 — same name plate as the login screen, one form code further on.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.status != AuthStatus.authenticated &&
          next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MOTO / CARD', style: AppText.micro()),
                    Text('FORM 02-B', style: AppText.micro()),
                  ],
                ),
                const DoubleRule(margin: EdgeInsets.only(top: 10)),
                const SizedBox(height: 48),
                Text('NOWE', style: AppText.display(size: 52)),
                Text(
                  'STANOWISKO',
                  style: AppText.display(size: 52, color: AppColors.oxideLit),
                ),
                const SizedBox(height: 14),
                Text(
                  'ZAKŁADAMY KARTĘ WARSZTATOWĄ',
                  style: AppText.micro().copyWith(letterSpacing: 9.5 * 0.2),
                ),
                LabeledField(
                  label: 'E-mail',
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: AppText.data(size: 14.5),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Podaj email';
                      if (!value.contains('@')) return 'Nieprawidłowy email';
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: 'Hasło',
                  hint: 'min. 6 znaków',
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    style: AppText.data(size: 14.5),
                    decoration: InputDecoration(
                      suffixIcon: RevealToggle(
                        obscured: _obscurePassword,
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Podaj hasło';
                      if (value.length < 6) {
                        return 'Hasło musi mieć minimum 6 znaków';
                      }
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: 'Potwierdź hasło',
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: AppText.data(size: 14.5),
                    decoration: InputDecoration(
                      suffixIcon: RevealToggle(
                        obscured: _obscureConfirmPassword,
                        onTap: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Potwierdź hasło';
                      }
                      if (value != _passwordController.text) {
                        return 'Hasła nie są zgodne';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 28),
                if (authState.errorMessage != null) ...[
                  FaultStrip(message: authState.errorMessage!),
                  const SizedBox(height: 20),
                ],
                GarageButton(
                  label: 'ZAŁÓŻ KARTĘ',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
                const SizedBox(height: 18),
                GarageButton.ghost(
                  label: 'MAM JUŻ KONTO',
                  trailingArrow: true,
                  onPressed: isLoading ? null : () => context.go('/login'),
                ),
                const SizedBox(height: 34),
                const DoubleRule(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('WARSZTAT / PL', style: AppText.micro()),
                    Text('REV. 03', style: AppText.micro()),
                  ],
                ),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
