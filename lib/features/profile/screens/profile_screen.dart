import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:si2_p1_mobile/features/auth/providers/auth_provider.dart';
import 'package:si2_p1_mobile/shared/widgets/glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  static const name = 'profile';

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  user?.fullName.isNotEmpty == true
                      ? user!.fullName.substring(0, 1).toUpperCase()
                      : '?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.fullName ?? 'Usuario',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user?.email ?? '—',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),

              // Info
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Nombre',
                      value: user?.fullName ?? '—',
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Correo',
                      value: user?.email ?? '—',
                    ),
                    if (user?.phone != null) ...[
                      const Divider(),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Teléfono',
                        value: user!.phone!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Cerrar sesión
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
