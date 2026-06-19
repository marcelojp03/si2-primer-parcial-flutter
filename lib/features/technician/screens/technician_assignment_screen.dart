import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:si2_p1_mobile/core/models/incident_model.dart';
import 'package:si2_p1_mobile/core/models/vehicle_model.dart';
import 'package:si2_p1_mobile/core/services/incident_service.dart';
import 'package:si2_p1_mobile/core/services/routing_factory.dart';
import 'package:si2_p1_mobile/core/services/routing/routing_service.dart';
import 'package:si2_p1_mobile/core/services/routing/route_result.dart';
import 'package:si2_p1_mobile/core/services/vehicle_service.dart';
import 'package:si2_p1_mobile/shared/widgets/app_toast.dart';
import 'package:si2_p1_mobile/shared/widgets/glass_card.dart';

class TechnicianAssignmentScreen extends ConsumerStatefulWidget {
  static const name = 'technician-assignment';
  final int assignmentId;
  final int incidentId;
  const TechnicianAssignmentScreen({super.key, required this.assignmentId, this.incidentId = 0});
  @override
  ConsumerState<TechnicianAssignmentScreen> createState() => _TechnicianAssignmentScreenState();
}

class _TechnicianAssignmentScreenState extends ConsumerState<TechnicianAssignmentScreen> {
  AssignmentModel? _assignment;
  IncidentModel? _incident;
  VehicleModel? _vehicle;
  AiAnalysisModel? _aiAnalysis;
  bool _loading = true;
  bool _tracking = false;
  String _currentStatus = '';
  Timer? _gpsTimer;
  LatLng? _myPosition;
  RouteResult? _routeResult;
  late final RoutingService _routingService;
  final MapController _techMapController = MapController();

  @override
  void initState() { _routingService = createRoutingService(); super.initState(); _load(); }
  @override
  void dispose() { _gpsTimer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    try {
      final incidentId = widget.incidentId > 0 ? widget.incidentId : widget.assignmentId;
      final svc = IncidentService();
      final a = await svc.getAssignment(incidentId);
      final inc = await svc.getIncident(incidentId);
      VehicleModel? v;
      if (inc.vehicleId > 0) {
        try { v = await VehicleService().getVehicleById(inc.vehicleId); } catch (_) {}
      }
      AiAnalysisModel? ai;
      try { ai = await svc.getAiAnalysis(incidentId); } catch (_) {}
      if (mounted) setState(() { _assignment = a; _incident = inc; _vehicle = v; _aiAnalysis = ai; _currentStatus = a?.assignmentStatus ?? ''; _loading = false; });
      // Reanudar tracking si ya estaba EN_CAMINO
      if (a?.assignmentStatus == 'EN_CAMINO' && mounted) {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
          setState(() => _tracking = true);
          _gpsTimer = Timer.periodic(const Duration(seconds: 8), (_) => _sendLocation());
          _sendLocation();
        }
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _startTracking() async {
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      AppToast.error(context, message: 'Permiso de ubicacion requerido');
      return;
    }
    setState(() => _tracking = true);
    await _updateStatus('EN_CAMINO');
    _gpsTimer = Timer.periodic(const Duration(seconds: 8), (_) => _sendLocation());
    _sendLocation();
  }

  Future<void> _sendLocation() async {
    if (_incident == null) return;
    try {
      final pos = await Geolocator.getCurrentPosition();
      await IncidentService().updateLocation(_incident!.id, pos.latitude, pos.longitude);
      if (mounted) setState(() => _myPosition = LatLng(pos.latitude, pos.longitude));
      _loadRoute();
    } catch (_) {}
  }

  Future<void> _loadRoute() async {
    if (_incident == null || _myPosition == null) return;
    final route = await _routingService.getRoute(
      _myPosition!,
      LatLng(_incident!.latitude, _incident!.longitude),
    );
    if (mounted) setState(() => _routeResult = route);
  }

  String _formatEta(DateTime eta) {
    final diff = eta.difference(DateTime.now());
    if (diff.isNegative) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    return '${h}h ${m}min';
  }

  Future<void> _updateStatus(String status) async {
    try {
      final updated = await IncidentService().updateAssignment(widget.assignmentId, {'assignment_status': status});
      if (mounted) setState(() { _assignment = updated; _currentStatus = status; });
    } catch (e) {
      if (mounted) AppToast.error(context, message: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _stopTracking() async {
    if (_currentStatus == 'EN_CAMINO') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Finalizar servicio?'),
          content: const Text('No has marcado "Llegué al lugar". ¿Estás seguro de que el servicio está completo?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Finalizar')),
          ],
        ),
      );
      if (confirm != true) return;
    }
    _gpsTimer?.cancel();
    setState(() => _tracking = false);
    await _updateStatus('COMPLETADO');
    if (mounted) {
      AppToast.success(context, message: 'Servicio finalizado');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Servicio Asignado')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assignment == null
              ? const Center(child: Text('Servicio no encontrado'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Incidente info ──
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _currentStatus == 'EN_CAMINO' ? Colors.orange.shade100 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(_currentStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _currentStatus == 'EN_CAMINO' ? Colors.orange.shade800 : Colors.grey.shade700)),
                                ),
                                const Spacer(),
                                Text('#${_incident?.id ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(_incident?.title ?? 'Sin título', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            if (_incident?.descriptionText != null && _incident!.descriptionText!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(_incident!.descriptionText!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                            ],
                            if (_vehicle != null) ...[
                              const SizedBox(height: 8),
                              Row(children: [
                                const Icon(Icons.directions_car_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${_vehicle!.brand} ${_vehicle!.model} · ${_vehicle!.plate}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ]),
                            ],
                            if (_assignment!.estimatedCost != null) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.monetization_on_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('Costo: Bs ${_assignment!.estimatedCost!.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ]),
                            ],
                          ],
                        ),
                      ),
                      // ── Analisis IA ──
                      if (_aiAnalysis != null) ...[
                        const SizedBox(height: 12),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
                                const SizedBox(width: 6),
                                Text('Análisis IA', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ]),
                              if (_aiAnalysis!.generatedSummary != null) ...[
                                const SizedBox(height: 6),
                                Text(_aiAnalysis!.generatedSummary!, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6, runSpacing: 4,
                                children: [
                                  if (_aiAnalysis!.predictedPriorityLevel != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                      child: Text(_aiAnalysis!.predictedPriorityLevel!, style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
                                    ),
                                  if (_aiAnalysis!.predictedRequiresTow == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                      child: const Text('Requiere remolque', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600)),
                                    ),
                                  if (_aiAnalysis!.confidenceScore != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                      child: Text('Confianza: ${(_aiAnalysis!.confidenceScore! * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
                                    ),
                                  if (_aiAnalysis!.transcribedAudio != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                      child: const Text('Audio transcrito', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.w600)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // ── Mapa ──
                      if (_incident != null) ...[
                        SizedBox(
                          height: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _techMapController,
                                  options: MapOptions(
                                    initialCenter: LatLng(_incident!.latitude, _incident!.longitude),
                                    initialZoom: 15,
                                  ),
                                  children: [
                                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.auxilio.mecanico'),
                              PolylineLayer(
                                polylines: [
                                  if (_routeResult != null && _routeResult!.points.isNotEmpty)
                                    Polyline(
                                      points: _routeResult!.points,
                                      color: Colors.green.withValues(alpha: 0.7),
                                      strokeWidth: 4,
                                    )
                                  else if (_myPosition != null)
                                    Polyline(
                                      points: [_myPosition!, LatLng(_incident!.latitude, _incident!.longitude)],
                                      color: Colors.green.withValues(alpha: 0.6),
                                      strokeWidth: 3,
                                    ),
                                ],
                              ),
                              MarkerLayer(markers: [
                                Marker(
                                  point: LatLng(_incident!.latitude, _incident!.longitude),
                                  width: 36, height: 36,
                                  child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
                                ),
                                if (_myPosition != null)
                                  Marker(
                                    point: _myPosition!,
                                    width: 32, height: 32,
                                    child: const Icon(Icons.directions_car_rounded, color: Colors.green, size: 32),
                                  ),
                              ]),
                              ],
                            ),
                            Positioned(
                              right: 8, bottom: 8,
                              child: GestureDetector(
                                onTap: () {
                                  final client = LatLng(_incident!.latitude, _incident!.longitude);
                                  final myPos = _myPosition;
                                  final points = [client, if (myPos != null) myPos];
                                  if (points.length > 1) {
                                    _techMapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(points), padding: const EdgeInsets.all(30)));
                                  } else {
                                    _techMapController.move(client, 15);
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
                      Row(children: [
                          const Icon(Icons.location_pin, color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Text('Ubicación del cliente', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          if (_incident!.referenceAddress != null) ...[
                            const SizedBox(width: 8),
                            Expanded(child: Text(_incident!.referenceAddress!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis)),
                          ],
                        ]),
                        if (_routeResult != null && !_routeResult!.hasError) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.route, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${_routeResult!.distanceKm.toStringAsFixed(1)} km · ~${_routeResult!.durationMinutes} min · Llega ${_formatEta(_routeResult!.eta)}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                        ] else if (_routeResult != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.route, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _routeResult!.errorMessage ?? 'ETA no disponible',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // ── Botones ──
                      if (_currentStatus == 'ASIGNADO' || _currentStatus == '') ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _startTracking,
                            icon: const Icon(Icons.route),
                            label: const Text('Iniciar traslado'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _updateStatus('CANCELADO'),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Rechazar servicio'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                      if (!_tracking && _currentStatus == 'CANCELADO') ...[
                        Center(child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(children: [
                            Icon(Icons.cancel, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 8),
                            Text('Servicio cancelado', style: TextStyle(fontSize: 16, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                          ]),
                        )),
                      ],
                      if (_tracking) ...[
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                              const SizedBox(height: 8),
                              Text('Enviando ubicación...', style: TextStyle(fontSize: 14, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                              Text('La app cliente puede ver tu posición', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_currentStatus == 'EN_CAMINO' || _tracking) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus('EN_SITIO'),
                            icon: const Icon(Icons.location_on),
                            label: const Text('Llegué al lugar'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_currentStatus == 'EN_SITIO' || _currentStatus == 'EN_PROCESO' || _tracking) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _stopTracking,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Finalizar servicio'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
