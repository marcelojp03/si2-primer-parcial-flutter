import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:si2_p1_mobile/config/theme/theme_provider.dart';
import 'package:si2_p1_mobile/core/services/sync_service.dart';
import 'package:si2_p1_mobile/shared/widgets/custom_filled_button.dart';
import 'package:si2_p1_mobile/shared/widgets/glass_card.dart';

class HomeScreen extends ConsumerWidget {
  static const name = 'home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeNotifierProvider);
    final pendingAsync = ref.watch(pendingIncidentsCountProvider);
    final pendingCount = pendingAsync.asData?.value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auxilio Mecánico'),
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: themeMode == ThemeMode.dark ? 'Modo claro' : 'Modo oscuro',
            onPressed: () => ref.read(themeNotifierProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner de emergencias pendientes offline
              if (pendingCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$pendingCount emergencia${pendingCount > 1 ? 's' : ''} pendiente${pendingCount > 1 ? 's' : ''} de envío',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Banner de emergencia
              GlassCard(
                padding: const EdgeInsets.all(20),
                backgroundColor: theme.colorScheme.primaryContainer.withOpacity(
                  0.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '¿Necesitas ayuda?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reporta una emergencia y te asignaremos un taller cercano.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomFilledButton(
                      text: 'Solicitar Auxilio',
                      icon: Icons.car_crash_rounded,
                      onPressed: () => context.go('/incidents/new'),
                      buttonColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Acceso rápido',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.directions_car_rounded,
                      label: 'Mis Vehículos',
                      onTap: () => context.go('/vehicles'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.history_rounded,
                      label: 'Historial',
                      onTap: () => context.go('/history'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.person_rounded,
                      label: 'Perfil',
                      onTap: () => context.go('/profile'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
