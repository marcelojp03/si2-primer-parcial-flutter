import 'package:latlong2/latlong.dart';

/// Resultado de un servicio de routing (OSRM, OpenRouteService, etc.).
///
/// Cuando [errorMessage] no es nulo significa que todos los providers
/// configurados fallaron. La pantalla debe mostrar el mensaje de error
/// en lugar de distancia/ETA, y dibujar la línea recta como fallback visual.
class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final DateTime eta;
  final String provider;

  /// Sólo se asigna cuando todos los providers fallaron.
  /// La pantalla debe mostrar este mensaje en lugar de distancia/ETA.
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.eta,
    required this.provider,
    this.errorMessage,
  });
}
