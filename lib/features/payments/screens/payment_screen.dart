import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:si2_p1_mobile/core/models/incident_model.dart';
import 'package:si2_p1_mobile/core/services/incident_service.dart';
import 'package:si2_p1_mobile/features/auth/providers/auth_provider.dart';
import 'package:si2_p1_mobile/shared/widgets/custom_filled_button.dart';
import 'package:si2_p1_mobile/shared/widgets/glass_card.dart';
import 'package:si2_p1_mobile/shared/widgets/app_toast.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  static const name = 'payment';
  final int incidentId;

  const PaymentScreen({super.key, required this.incidentId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _method = 'CASH';
  bool _isLoading = false;
  AssignmentModel? _assignment;
  final _methods = ['CASH', 'QR', 'TRANSFER'];

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  Future<void> _loadAssignment() async {
    try {
      final a = await IncidentService().getAssignment(widget.incidentId);
      if (mounted) setState(() => _assignment = a);
    } catch (_) {}
  }

  Future<void> _pay() async {
    final clientUserId = ref.read(authProvider).user?.id;
    if (clientUserId == null || _assignment == null) {
      AppToast.warning(context, message: 'No se puede procesar el pago ahora');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final payment = await IncidentService().makePayment(
        serviceAssignmentId: _assignment!.id,
        clientUserId: clientUserId,
        amount: _assignment!.finalCost ?? _assignment!.estimatedCost ?? 0.0,
        paymentMethod: _method,
      );
      if (!mounted) return;
      if (_method == 'QR') {
        context.push(
          '/incidents/${widget.incidentId}/qr-payment/${payment.id}',
        );
      } else {
        AppToast.success(context, message: 'Pago registrado correctamente');
        context.go('/incidents/${widget.incidentId}/rating/${_assignment!.id}');
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

    return Scaffold(
      appBar: AppBar(title: const Text('Pago del servicio')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecciona el método de pago',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ..._methods.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    onTap: () => setState(() => _method = m),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    backgroundColor: _method == m
                        ? theme.colorScheme.primaryContainer
                        : null,
                    child: Row(
                      children: [
                        Icon(
                          m == 'CASH'
                              ? Icons.money_rounded
                              : m == 'QR'
                              ? Icons.qr_code_rounded
                              : Icons.swap_horiz_rounded,
                          color: _method == m
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          m,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: _method == m
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (_method == m)
                          Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              CustomFilledButton(
                text: 'Confirmar pago',
                isLoading: _isLoading,
                onPressed: _pay,
                icon: Icons.payment_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
