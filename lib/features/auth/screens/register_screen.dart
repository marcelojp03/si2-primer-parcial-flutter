import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:si2_p1_mobile/shared/widgets/custom_filled_button.dart';
import 'package:si2_p1_mobile/shared/widgets/custom_input_field.dart';
import 'package:si2_p1_mobile/features/auth/providers/auth_provider.dart';
import 'package:si2_p1_mobile/shared/widgets/app_toast.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  static const name = 'register';

  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullNameCtrl = TextEditingController();
  final _ciCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _ciCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final notifier = ref.read(authProvider.notifier);
    await notifier.register(
      fullName: _fullNameCtrl.text.trim(),
      ci: _ciCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
    );
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.status == AuthStatus.authenticated) {
      context.go('/home');
    } else if (state.errorMessage != null) {
      AppToast.error(context, message: state.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).status == AuthStatus.checking;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/login')),
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              CustomInputField(
                label: 'Nombre completo',
                controller: _fullNameCtrl,
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: 'Cédula de identidad (CI)',
                controller: _ciCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: 'Correo electrónico',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: 'Teléfono (opcional)',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: 'Contraseña',
                controller: _passCtrl,
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 32),
              CustomFilledButton(
                text: 'Crear cuenta',
                isLoading: isLoading,
                onPressed: _register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
