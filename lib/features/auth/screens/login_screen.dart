import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:si2_p1_mobile/shared/widgets/custom_filled_button.dart';
import 'package:si2_p1_mobile/shared/widgets/custom_input_field.dart';
import 'package:si2_p1_mobile/features/auth/providers/auth_provider.dart';
import 'package:si2_p1_mobile/shared/widgets/app_toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const name = 'login';

  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final notifier = ref.read(authProvider.notifier);
    await notifier.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
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
    final theme = Theme.of(context);
    final isLoading = ref.watch(authProvider).status == AuthStatus.checking;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.car_repair_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Bienvenido',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión para solicitar auxilio mecánico',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 40),
              CustomInputField(
                label: 'Correo electrónico',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
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
                text: 'Iniciar sesión',
                isLoading: isLoading,
                onPressed: _login,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(
                    '¿No tienes cuenta? Regístrate',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
