import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:si2_p1_mobile/core/models/incident_model.dart';
import 'package:si2_p1_mobile/core/services/incident_service.dart';
import 'package:si2_p1_mobile/shared/utils/responsive.dart';
import 'package:si2_p1_mobile/shared/widgets/app_toast.dart';
import 'package:si2_p1_mobile/shared/widgets/glass_card.dart';

class QrPaymentScreen extends ConsumerStatefulWidget {
  static const name = 'qr-payment';
  final int incidentId;
  final int paymentId;

  const QrPaymentScreen({
    super.key,
    required this.incidentId,
    required this.paymentId,
  });

  @override
  ConsumerState<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends ConsumerState<QrPaymentScreen> {
  Timer? _statusTimer;
  QRGenerateResponse? _qrData;
  AssignmentModel? _assignment;
  bool _loading = true;
  bool _paid = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initQR();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _initQR() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = IncidentService();
      final qr = await service.generateQR(widget.paymentId);
      final assignment = await service.getAssignment(widget.incidentId);
      if (mounted) {
        setState(() {
          _qrData = qr;
          _assignment = assignment;
          _loading = false;
        });
      }
      _statusTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _checkStatus(),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _checkStatus() async {
    try {
      final status = await IncidentService().checkQRStatus(widget.paymentId);
      if (status.paid && mounted) {
        _statusTimer?.cancel();
        setState(() => _paid = true);
        AppToast.success(context, message: '¡Pago confirmado!');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go(
            '/incidents/${widget.incidentId}/rating/${_assignment?.id ?? 0}',
          );
        }
      }
    } catch (_) {
      // Ignorar errores de polling silenciosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = Responsive.of(context);
    final amount = _assignment?.finalCost ?? _assignment?.estimatedCost;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago con QR'),
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/incidents/${widget.incidentId}/payment'),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(r.wp(6)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: r.wp(12),
                        color: Colors.red,
                      ),
                      SizedBox(height: r.hp(2)),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: r.hp(2)),
                      ElevatedButton(
                        onPressed: _initQR,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(r.wp(6)),
                child: Column(
                  children: [
                    Text(
                      _paid ? '¡Pago confirmado!' : 'Escanea el código QR',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: r.fontSize(22),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: r.hp(1)),
                    Text(
                      _paid
                          ? 'Tu pago fue procesado correctamente.'
                          : 'Usa tu app bancaria para escanear y pagar.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: r.hp(2.5)),
                    Image.asset(
                      'assets/images/logovpay.png',
                      height: r.hp(6),
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: r.hp(2.5)),
                    GlassCard(
                      padding: EdgeInsets.all(r.wp(4)),
                      child: _paid
                          ? Padding(
                              padding: EdgeInsets.all(r.wp(10)),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: r.wp(20),
                                color: Colors.green,
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(r.radius(12)),
                              child: Image.memory(
                                base64Decode(_qrData!.qrBase64),
                                width: r.wp(65),
                                height: r.wp(65),
                                fit: BoxFit.contain,
                              ),
                            ),
                    ),
                    if (amount != null) ...[
                      SizedBox(height: r.hp(2.5)),
                      GlassCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.wp(5),
                          vertical: r.hp(1.8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total a pagar',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              'Bs ${amount.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (!_paid) ...[
                      SizedBox(height: r.hp(2.5)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: r.wp(3.5),
                            height: r.wp(3.5),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: r.wp(2)),
                          Text(
                            'Verificando pago cada 5 segundos...',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
