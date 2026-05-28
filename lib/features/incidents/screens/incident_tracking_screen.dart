import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:si2_p1_mobile/config/theme/app_theme.dart';
import 'package:si2_p1_mobile/core/models/incident_model.dart';
import 'package:si2_p1_mobile/core/services/incident_service.dart';
import 'package:si2_p1_mobile/core/services/ws_service.dart';
import 'package:si2_p1_mobile/shared/widgets/glass_card.dart';

class IncidentTrackingScreen extends ConsumerStatefulWidget {
  static const name = 'incident-tracking';
  final int incidentId;

  const IncidentTrackingScreen({super.key, required this.incidentId});

  @override
  ConsumerState<IncidentTrackingScreen> createState() =>
      _IncidentTrackingScreenState();
}

class _IncidentTrackingScreenState
    extends ConsumerState<IncidentTrackingScreen> {
  Timer? _pollingTimer;
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  IncidentModel? _incident;
  AssignmentModel? _assignment;
  WorkshopModel? _workshop;
  // Posición en tiempo real del técnico (actualizada vía WS)
  LatLng? _technicianPosition;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchData(),
    );
    _subscribeWs();
  }

  void _subscribeWs() {
    final ws = ref.read(wsServiceProvider);
    _wsSub = ws.on('incident.location_updated').listen((msg) {
      final payload = msg['payload'] as Map<String, dynamic>?;
      if (payload == null) return;
      final incidentId = payload['incident_id'] as int?;
      if (incidentId != widget.incidentId) return;
      final lat = (payload['latitude'] as num?)?.toDouble();
      final lng = (payload['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null && mounted) {
        setState(() => _technicianPosition = LatLng(lat, lng));
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final service = IncidentService();
      final incident = await service.getIncident(widget.incidentId);
      final assignment = await service.getAssignment(widget.incidentId);
      if (assignment != null &&
          (_workshop == null ||
              assignment.workshopId != _assignment?.workshopId)) {
        final workshop = await service.getWorkshop(assignment.workshopId);
        if (mounted) setState(() => _workshop = workshop);
      }
      if (mounted) {
        setState(() {
          _incident = incident;
          _assignment = assignment;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  String _statusMessage(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDIENTE':
        return 'Buscando talleres disponibles...';
      case 'NOTIFICADO':
        return 'Notificando talleres cercanos...';
      case 'ACEPTADO':
        return '¡Un taller aceptó tu solicitud!';
      case 'EN_PROCESO':
      case 'ASIGNADO':
      case 'EN_CAMINO':
        return 'El técnico está en camino';
      case 'ATENDIDO':
        return 'Servicio completado. Proceder al pago.';
      case 'PENDIENTE_PAGO':
        return 'Pendiente de pago';
      case 'PAGADO':
        return '¡Pago confirmado! Puedes calificar el servicio.';
      case 'CANCELADO':
        return 'Servicio cancelado';
      default:
        return 'Actualizando estado...';
    }
  }

  String get _displayStatus {
    if (_assignment != null) return _assignment!.assignmentStatus;
    return _incident?.statusLabel ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento'),
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchData,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Mapa ───────────────────────────────────────────────
                    if (_incident != null) ...[
                      SizedBox(
                        height: 210,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                _incident!.latitude,
                                _incident!.longitude,
                              ),
                              initialZoom: 14,
                              interactionOptions: const InteractionOptions(
                                flags:
                                    InteractiveFlag.pinchZoom |
                                    InteractiveFlag.drag,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.auxilio.mecanico',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      _incident!.latitude,
                                      _incident!.longitude,
                                    ),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                  if (_technicianPosition != null)
                                    Marker(
                                      point: _technicianPosition!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.directions_car_rounded,
                                        color: Colors.green,
                                        size: 36,
                                      ),
                                    )
                                  else if (_workshop != null)
                                    Marker(
                                      point: LatLng(
                                        _workshop!.latitude,
                                        _workshop!.longitude,
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.build_circle_rounded,
                                        color: Colors.blue,
                                        size: 36,
                                      ),
                                    ),
                                ],
                              ),
                              SimpleAttributionWidget(
                                source: const Text('© OpenStreetMap'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tu ubicación',
                            style: theme.textTheme.labelSmall,
                          ),
                          if (_workshop != null) ...[
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.build_circle_rounded,
                              color: Colors.blue,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _workshop!.name,
                                style: theme.textTheme.labelSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Estado principal ────────────────────────────────
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.incidentStatusColor(
                                    _displayStatus,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _displayStatus,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _statusMessage(_displayStatus),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Incidente #${_incident?.id}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                          Text(
                            _incident?.title ?? '—',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_incident?.requiresTow == true) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_shipping_rounded,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Requiere remolque',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Datos de la asignación ───────────────────────────
                    if (_assignment != null) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Servicio asignado',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Estado: ${_assignment!.assignmentStatus}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_workshop != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Taller: ${_workshop!.name}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                            if (_assignment!.estimatedCost != null) ...[
                              const Divider(height: 16),
                              Text(
                                'Costo estimado: Bs ${_assignment!.estimatedCost!.toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                            if (_assignment!.finalCost != null) ...[
                              const Divider(height: 16),
                              Text(
                                'Costo final: Bs ${_assignment!.finalCost!.toStringAsFixed(2)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // ── Botón de pago ──────────────────────────────────
                    if (_assignment?.canPay == true) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => context.push(
                          '/incidents/${widget.incidentId}/payment',
                        ),
                        icon: const Icon(Icons.payment_rounded),
                        label: const Text('Proceder al pago'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                    ],

                    // ── Botón de calificación ───────────────────────────
                    if (_assignment?.canRate == true) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => context.push(
                          '/incidents/${widget.incidentId}/rating/${_assignment!.id}',
                        ),
                        icon: const Icon(Icons.star_rounded),
                        label: const Text('Calificar servicio'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Actualizando cada 15 segundos',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
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
