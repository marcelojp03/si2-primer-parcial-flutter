import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:si2_p1_mobile/config/theme/app_theme.dart';
import 'package:si2_p1_mobile/core/models/incident_model.dart';
import 'package:si2_p1_mobile/core/models/vehicle_model.dart';
import 'package:si2_p1_mobile/core/services/incident_service.dart';
import 'package:si2_p1_mobile/core/services/vehicle_service.dart';
import 'package:si2_p1_mobile/core/services/ws_service.dart';
import 'package:si2_p1_mobile/core/services/routing_factory.dart';
import 'package:si2_p1_mobile/core/services/routing/routing_service.dart';
import 'package:si2_p1_mobile/core/services/routing/route_result.dart';
import 'package:si2_p1_mobile/shared/widgets/app_toast.dart';
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
  final List<StreamSubscription<Map<String, dynamic>>> _wsSubs = [];
  WsService? _ws;
  IncidentModel? _incident;
  AssignmentModel? _assignment;
  WorkshopModel? _workshop;
  VehicleModel? _vehicle;
  AiAnalysisModel? _aiAnalysis;
  // Posición en tiempo real del técnico (actualizada vía WS)
  LatLng? _technicianPosition;
  RouteResult? _routeResult;
  late final RoutingService _routingService;
  final MapController _mapController = MapController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _routingService = createRoutingService();
    _fetchData();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _fetchData(),
    );
    _subscribeWs();
  }

  void _subscribeWs() {
    final ws = ref.read(wsServiceProvider);
    _ws = ws;
    ws.subscribeIncident(widget.incidentId);

    _wsSubs.add(ws.on('incident.location_updated').listen((msg) {
      final payload = msg['payload'] as Map<String, dynamic>?;
      if (payload == null) return;
      final incidentId = payload['incident_id'] as int?;
      if (incidentId != widget.incidentId) return;
      final lat = (payload['latitude'] as num?)?.toDouble();
      final lng = (payload['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null && mounted) {
        setState(() => _technicianPosition = LatLng(lat, lng));
        _loadRoute();
      }
    }));

    _wsSubs.add(ws.on('incident.status_changed').listen((msg) {
      if (!mounted) return;
      _fetchData();
    }));

    _wsSubs.add(ws.on('assignment.accepted').listen((msg) {
      if (!mounted) return;
      _fetchData();
    }));
  }

  @override
  void dispose() {
    _ws?.unsubscribeIncident(widget.incidentId);
    _pollingTimer?.cancel();
    for (final sub in _wsSubs) {
      sub.cancel();
    }
    _wsSubs.clear();
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
      if (incident.vehicleId > 0 && _vehicle == null) {
        try {
          final v = await VehicleService().getVehicleById(incident.vehicleId);
          if (mounted) setState(() => _vehicle = v);
        } catch (_) {}
      }
      if (_aiAnalysis == null) {
        try {
          final ai = await IncidentService().getAiAnalysis(widget.incidentId);
          if (mounted) setState(() => _aiAnalysis = ai);
        } catch (_) {}
      }
      // Cargar ruta OSRM
      _loadRoute();
      if (mounted) {
        setState(() {
          _incident = incident;
          _assignment = assignment;
          _loading = false;
          _error = null;
        });
        if (assignment == null) _loadAcceptedCandidates();
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
    final isTow = _incident?.requiresTow == true;
    final isClientGoes = _incident?.isClientGoesToWorkshop == true;
    final auxilio = isTow ? 'La grúa' : 'El auxilio';

    if (isClientGoes) {
      switch (status?.toUpperCase()) {
        case 'PENDIENTE':
          return 'Buscando talleres disponibles...';
        case 'NOTIFICADO':
          return 'Notificando talleres cercanos...';
        case 'ACEPTADO':
          return '¡Un taller aceptó tu solicitud!';
        case 'ASIGNADO':
          return 'Taller listo, dirígete al taller';
        case 'EN_SITIO':
          return 'Has llegado al taller';
        case 'EN_PROCESO':
          return 'Atención en curso';
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

    switch (status?.toUpperCase()) {
      case 'PENDIENTE':
        return 'Buscando talleres disponibles...';
      case 'NOTIFICADO':
        return 'Notificando talleres cercanos...';
      case 'ACEPTADO':
        return '¡Un taller aceptó tu solicitud!';
      case 'ASIGNADO':
        return 'Auxilio asignado, esperando que salga hacia tu ubicación';
      case 'EN_CAMINO':
        return '$auxilio está en camino';
      case 'EN_SITIO':
        return '$auxilio llegó a tu ubicación';
      case 'EN_PROCESO':
        return 'Atención en curso';
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

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  String get _displayStatus {
    if (_assignment != null) return _assignment!.assignmentStatus;
    return _incident?.statusLabel ?? '';
  }

  Widget _quoteStatusBadge(ThemeData theme) {
    final status = _assignment?.quotationStatus;
    switch (status) {
      case 'PENDIENTE':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Pendiente', style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
        );
      case 'APROBADO':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Aprobada', style: TextStyle(fontSize: 11, color: Colors.green.shade800)),
        );
      case 'RECHAZADO':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Rechazada', style: TextStyle(fontSize: 11, color: Colors.red.shade800)),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  List<WorkshopCandidateModel> _acceptedCandidates = [];
  bool _selectingWorkshop = false;

  Future<void> _loadAcceptedCandidates() async {
    if (_assignment != null) return;
    try {
      final list = await IncidentService().getAcceptedCandidates(widget.incidentId);
      if (mounted) setState(() => _acceptedCandidates = list);
    } catch (_) {}
  }

  Future<void> _selectWorkshop(int workshopId) async {
    setState(() => _selectingWorkshop = true);
    try {
      final assignment = await IncidentService().selectWorkshop(widget.incidentId, workshopId);
      if (mounted) {
        setState(() {
          _assignment = assignment;
          _acceptedCandidates = [];
          _selectingWorkshop = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Taller seleccionado correctamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _selectingWorkshop = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    }
  }

  String _formatEta(DateTime eta) {
    final diff = eta.difference(DateTime.now());
    if (diff.isNegative) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    return '${h}h ${m}min';
  }

  Future<void> _loadRoute() async {
    if (_incident == null) return;
    final client = LatLng(_incident!.latitude, _incident!.longitude);
    LatLng? target;
    if (_technicianPosition != null) {
      target = _technicianPosition;
    } else if (_workshop != null) {
      target = LatLng(_workshop!.latitude, _workshop!.longitude);
    }
    if (target != null) {
      final route = await _routingService.getRoute(client, target);
      if (mounted) setState(() => _routeResult = route);
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final launched = await launchUrlString(uri.toString(), mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el mapa')));
    }
  }

  Future<void> _respondQuote(String status) async {
    if (_assignment == null) return;
    try {
      final service = IncidentService();
      final updated = await service.respondQuote(_assignment!.id, status);
      if (mounted) {
        setState(() => _assignment = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'APROBADO' ? 'Cotización aprobada' : 'Cotización rechazada'),
            backgroundColor: status == 'APROBADO' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    }
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
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
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
                              PolylineLayer(
                                polylines: [
                                  if (_routeResult != null && _routeResult!.points.isNotEmpty)
                                    Polyline(
                                      points: _routeResult!.points,
                                      color: Colors.blue.withValues(alpha: 0.7),
                                      strokeWidth: 4,
                                      borderStrokeWidth: 1,
                                      borderColor: Colors.white.withValues(alpha: 0.3),
                                    )
                                  else ...[
                                    if (_incident != null && _workshop != null)
                                      Polyline(
                                        points: [
                                          LatLng(_incident!.latitude, _incident!.longitude),
                                          LatLng(_workshop!.latitude, _workshop!.longitude),
                                        ],
                                        color: _incident!.isClientGoesToWorkshop
                                            ? Colors.blue.withValues(alpha: 0.6)
                                            : Colors.orange.withValues(alpha: 0.6),
                                        strokeWidth: 3,
                                        borderStrokeWidth: 1,
                                        borderColor: Colors.white.withValues(alpha: 0.3),
                                      ),
                                    if (_incident != null && _technicianPosition != null && !_incident!.isClientGoesToWorkshop)
                                      Polyline(
                                        points: [
                                          LatLng(_technicianPosition!.latitude, _technicianPosition!.longitude),
                                          LatLng(_incident!.latitude, _incident!.longitude),
                                        ],
                                        color: Colors.green.withValues(alpha: 0.7),
                                        strokeWidth: 3,
                                        borderStrokeWidth: 1,
                                        borderColor: Colors.white.withValues(alpha: 0.3),
                                      ),
                                  ],
                                ],
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
                                  if (_incident!.isClientGoesToWorkshop &&
                                      _workshop != null)
                                    Marker(
                                      point: LatLng(
                                        _workshop!.latitude,
                                        _workshop!.longitude,
                                      ),
                                      width: 44,
                                      height: 44,
                                      child: const Icon(
                                        Icons.store_rounded,
                                        color: Colors.blue,
                                        size: 40,
                                      ),
                                    )
                                  else if (_technicianPosition != null)
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
                          Positioned(
                            right: 8, bottom: 8,
                            child: GestureDetector(
                              onTap: () {
                                final client = LatLng(_incident!.latitude, _incident!.longitude);
                                final tech = _technicianPosition;
                                final ws = _workshop != null ? LatLng(_workshop!.latitude, _workshop!.longitude) : null;
                                final points = [client, if (tech != null) tech, if (ws != null) ws];
                                if (points.length > 1) {
                                  _mapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(points), padding: const EdgeInsets.all(30)));
                                } else {
                                  _mapController.move(client, 14);
                                }
                              },
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                                child: const Icon(Icons.my_location, size: 18, color: Colors.blue),
                              ),
                            ),
                          ),
                          ],
                        ),
                      ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.location_pin, color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Text('Tu ubicación', style: theme.textTheme.labelSmall),
                          if (_workshop != null && _incident?.isClientGoesToWorkshop == true) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.store_rounded, color: Colors.blue, size: 14),
                            const SizedBox(width: 4),
                            Expanded(child: Text(_workshop!.name, style: theme.textTheme.labelSmall, overflow: TextOverflow.ellipsis)),
                          ],
                        ],
                      ),
                      if (_workshop != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _incident?.isClientGoesToWorkshop == true ? Icons.arrow_forward : Icons.arrow_back,
                              size: 14, color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _incident?.isClientGoesToWorkshop == true
                                  ? 'Ruta hacia el taller'
                                  : _technicianPosition != null
                                      ? 'Auxilio en camino hacia ti'
                                      : 'Taller de origen',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                      if (_routeResult != null && !_routeResult!.hasError) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.route, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${_routeResult!.distanceKm.toStringAsFixed(1)} km · ~${_routeResult!.durationMinutes} min · Llega ${_formatEta(_routeResult!.eta)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ] else if (_routeResult != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.route, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              _routeResult!.errorMessage ?? 'ETA no disponible',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ],
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
                          if (_vehicle != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.directions_car_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${_vehicle!.brand} ${_vehicle!.model} · ${_vehicle!.plate}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
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
                          if (_incident?.isClientGoesToWorkshop == true) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.directions_car_rounded, size: 16, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text('Tú llevas el vehículo al taller',
                                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            if (_workshop != null) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _openMaps(_workshop!.latitude, _workshop!.longitude),
                                  icon: const Icon(Icons.map_outlined, size: 18),
                                  label: const Text('Abrir en Google Maps'),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                                ),
                              ),
                              if (_assignment?.assignmentStatus == 'ASIGNADO') ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final updated = await IncidentService().updateAssignment(_assignment!.id, {'assignment_status': 'EN_SITIO'});
                                        if (mounted) setState(() => _assignment = updated);
                                        AppToast.success(context, message: 'Has llegado al taller');
                                      } catch (e) {
                                        if (mounted) AppToast.error(context, message: e.toString().replaceFirst('Exception: ', ''));
                                      }
                                    },
                                    icon: const Icon(Icons.location_on, size: 18),
                                    label: const Text('Llegué al taller'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ],
                      ),
                    ),

                    // ── Cancelar emergencia ───────────────────────────────
                    if (_assignment == null && _acceptedCandidates.isEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('¿Cancelar emergencia?'),
                                content: const Text('Se cancelará la búsqueda de taller. ¿Estás seguro?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, cancelar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await IncidentService().cancelIncident(widget.incidentId);
                                if (mounted) {
                                  AppToast.info(context, message: 'Emergencia cancelada');
                                  _fetchData();
                                }
                              } catch (e) {
                                if (mounted) AppToast.error(context, message: e.toString().replaceFirst('Exception: ', ''));
                              }
                            }
                          },
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancelar emergencia'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ),
                    ],

                    // ── Análisis IA ────────────────────────────────────────
                    if (_aiAnalysis != null) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, size: 18, color: Colors.blue),
                                const SizedBox(width: 6),
                                Text('Análisis IA', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_aiAnalysis!.generatedSummary != null)
                              Text(_aiAnalysis!.generatedSummary!, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8, runSpacing: 4,
                              children: [
                                if (_aiAnalysis!.predictedPriorityLevel != null)
                                  _chip(_aiAnalysis!.predictedPriorityLevel!, Colors.orange),
                                if (_aiAnalysis!.predictedRequiresTow == true)
                                  _chip('Requiere remolque', Colors.red),
                                if (_aiAnalysis!.confidenceScore != null)
                                  _chip('Confianza: ${(_aiAnalysis!.confidenceScore! * 100).toStringAsFixed(0)}%', Colors.blue),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Seleccionar taller (candidatos aceptados) ───────────
                    if (_acceptedCandidates.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.handshake_rounded, size: 18, color: Colors.green),
                                const SizedBox(width: 6),
                                Text('Talleres que aceptaron',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Elige el taller que realizará el servicio',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            ..._acceptedCandidates.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Taller #${c.workshopId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        if (c.distanceKm != null)
                                          Text('${c.distanceKm!.toStringAsFixed(1)} km', style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _selectingWorkshop ? null : () => _selectWorkshop(c.workshopId),
                                    icon: const Icon(Icons.check_circle, size: 18),
                                    label: const Text('Elegir'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],

                    // ── Cotización ────────────────────────────────────────
                    if (_assignment != null && _assignment!.estimatedCost != null) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.blue),
                                const SizedBox(width: 6),
                                Text(
                                  'Cotización',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                const Spacer(),
                                _quoteStatusBadge(theme),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Costo estimado: Bs ${_assignment!.estimatedCost!.toStringAsFixed(2)}',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (_assignment!.estimatedCompletionMinutes != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Tiempo estimado: ${_assignment!.estimatedCompletionMinutes} min',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                            if (_assignment!.quotationDescription != null) ...[
                              const Divider(height: 16),
                              Text(
                                _assignment!.quotationDescription!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            if (_assignment!.hasPendingQuote) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _respondQuote('APROBADO'),
                                      icon: const Icon(Icons.check_circle, size: 18),
                                      label: const Text('Aprobar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _respondQuote('RECHAZADO'),
                                      icon: const Icon(Icons.cancel, size: 18),
                                      label: const Text('Rechazar'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

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
                        'Tiempo real · actualización automática',
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
