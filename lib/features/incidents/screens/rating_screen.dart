import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:si2_p1_mobile/core/services/incident_service.dart';
import 'package:si2_p1_mobile/features/auth/providers/auth_provider.dart';
import 'package:si2_p1_mobile/shared/widgets/app_toast.dart';
import 'package:si2_p1_mobile/shared/widgets/custom_filled_button.dart';
import 'package:si2_p1_mobile/shared/widgets/glass_card.dart';

class RatingScreen extends ConsumerStatefulWidget {
  static const name = 'rating';
  final int incidentId;
  final int serviceAssignmentId;

  const RatingScreen({
    super.key,
    required this.incidentId,
    required this.serviceAssignmentId,
  });

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _score = 0;
  final _commentCtrl = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  static const _labels = [
    '',
    'Muy malo',
    'Malo',
    'Regular',
    'Bueno',
    'Excelente',
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_score == 0) {
      AppToast.warning(context, message: 'Selecciona una calificación');
      return;
    }
    final clientUserId = ref.read(authProvider).user?.id;
    if (clientUserId == null) return;

    setState(() => _isLoading = true);
    try {
      await IncidentService().rateService(
        serviceAssignmentId: widget.serviceAssignmentId,
        clientUserId: clientUserId,
        score: _score,
        comment: _commentCtrl.text.trim().isEmpty
            ? null
            : _commentCtrl.text.trim(),
      );
      if (mounted) {
        setState(() => _submitted = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_submitted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 72, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                '¡Gracias por tu calificación!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Redirigiendo al inicio...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificar servicio'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(
                Icons.build_circle_rounded,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                '¿Cómo fue el servicio?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tu opinión nos ayuda a mejorar',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Estrellas
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _score = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        _score >= star
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 48,
                        color: Colors.amber,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _score == 0 ? 'Toca para calificar' : _labels[_score],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _score == 0
                      ? theme.colorScheme.onSurface.withOpacity(0.4)
                      : Colors.amber.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Comentario
              GlassCard(
                padding: const EdgeInsets.all(4),
                child: TextField(
                  controller: _commentCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Comentario opcional...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                  maxLength: 300,
                ),
              ),
              const Spacer(),
              CustomFilledButton(
                text: 'Enviar calificación',
                isLoading: _isLoading,
                onPressed: _submit,
                icon: Icons.send_rounded,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  'Omitir',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
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
