import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:si2_p1_mobile/features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  static const name = 'splash';
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _checkAndNavigate);
  }

  void _checkAndNavigate() {
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      final role = authState.user?.role.toUpperCase();
      if (role == 'TECNICO') {
        context.go('/technician/home');
      } else {
        context.go('/home');
      }
    } else if (authState.status == AuthStatus.notAuthenticated) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen<AuthState>(authProvider, (_, state) {
      if (state.status == AuthStatus.authenticated) {
        final role = state.user?.role.toUpperCase();
        if (role == 'TECNICO') {
          context.go('/technician/home');
        } else {
          context.go('/home');
        }
      } else if (state.status == AuthStatus.notAuthenticated) {
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.car_repair_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            Text('Auxilio Mecánico', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Plataforma de emergencias vehiculares', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60)),
            const SizedBox(height: 48),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}
