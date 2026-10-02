import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/double_rule.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_button.dart';
import '../widgets/labeled_field.dart';

/// §6 row 1 — a name plate, not a SaaS form. Wordmark, rivets, labels above
/// the fields, technical markings on the edges.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(
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
                    Text('Nº 01', style: AppText.micro()),
                  ],
                ),
                const DoubleRule(margin: EdgeInsets.only(top: 10)),
                const SizedBox(height: 56),
                const _Wordmark(),
                const SizedBox(height: 18),
                const _Rivets(),
                const SizedBox(height: 14),
                Text(
                  'SERWIS · PALIWO · PRZEBIEG',
                  style: AppText.micro().copyWith(letterSpacing: 9.5 * 0.22),
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
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
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
                const SizedBox(height: 28),
                if (authState.errorMessage != null) ...[
                  FaultStrip(message: authState.errorMessage!),
                  const SizedBox(height: 20),
                ],
                GarageButton(
                  label: 'ZALOGUJ',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
                const SizedBox(height: 18),
                GarageButton.ghost(
                  label: 'ZAREJESTRUJ SIĘ',
                  trailingArrow: true,
                  onPressed: isLoading ? null : () => context.go('/register'),
                ),
                const SizedBox(height: 34),
                const DoubleRule(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('WARSZTAT / PL', style: AppText.micro()),
                    Text('FORM 02-A', style: AppText.micro()),
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

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MOTO/', style: AppText.display(size: 58)),
        Text(
          'CARD',
          style: AppText.display(size: 58, color: AppColors.oxideLit),
        ),
      ],
    );
  }
}

class _Rivets extends StatelessWidget {
  const _Rivets();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        4,
        (_) => Container(
          margin: const EdgeInsets.only(right: 7),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFF3E3B33),
            border: Border.all(color: const Color(0xFF514C42), width: 1),
          ),
        ),
      ),
    );
  }
}

