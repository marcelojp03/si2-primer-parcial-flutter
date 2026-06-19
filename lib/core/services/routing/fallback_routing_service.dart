import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';
import 'route_result.dart';

/// Servicio de routing con fallback entre providers + caché por ruta + throttle.
///
/// Orden de providers: OSRM → ORS (si tiene API key).
/// Si todos fallan devuelve un RouteResult con errorMessage = "ETA no disponible".
///
/// Throttle: no recalcula si:
///   - Pasaron menos de [minInterval] desde la última llamada para la misma ruta
///   - Y el origen/destino no se movieron más de [minDistanceMeters] metros
///
/// La caché es PER RUTA (key = "lat,lng-lat,lng"), no global.
/// Si se pide una ruta diferente, se calcula sin esperar el throttle.
class FallbackRoutingService extends RoutingService {
  final List<RoutingService> _providers;
  final Duration minInterval;
  final double minDistanceMeters;

  final Map<String, _CacheEntry> _cache = {};

  FallbackRoutingService({
    required List<RoutingService> providers,
    this.minInterval = const Duration(seconds: 30),
    this.minDistanceMeters = 50,
  }) : _providers = List.unmodifiable(providers);

  @override
  Future<RouteResult?> getRoute(LatLng origin, LatLng destination) async {
    final key = _routeKey(origin, destination);
    final cached = _cache[key];

    if (cached != null && _shouldSkip(cached, origin, destination)) {
      return cached.result;
    }

    for (final provider in _providers) {
      try {
        final result = await provider.getRoute(origin, destination);
        if (result != null) {
          _cache[key] = _CacheEntry(
            result: result,
            timestamp: DateTime.now(),
            origin: origin,
            dest: destination,
          );
          return result;
        }
      } catch (_) {}
    }

    final errorResult = RouteResult(
      points: [],
      distanceKm: 0,
      durationMinutes: 0,
      eta: DateTime.now(),
      provider: 'fallback',
      errorMessage: 'ETA no disponible',
    );
    _cache[key] = _CacheEntry(
      result: errorResult,
      timestamp: DateTime.now(),
      origin: origin,
      dest: destination,
    );
    return errorResult;
  }

  bool _shouldSkip(_CacheEntry entry, LatLng origin, LatLng dest) {
    if (entry.result.hasError) return false;
    if (DateTime.now().difference(entry.timestamp) >= minInterval) return false;
    final distOrigin = _haversine(entry.origin, origin);
    final distDest = _haversine(entry.dest, dest);
    if (distOrigin >= minDistanceMeters || distDest >= minDistanceMeters) return false;
    return true;
  }

  String _routeKey(LatLng origin, LatLng dest) {
    return '${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}-'
        '${dest.latitude.toStringAsFixed(6)},${dest.longitude.toStringAsFixed(6)}';
  }

  double _haversine(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    return r * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  double _toRad(double deg) => deg * pi / 180;
}

class _CacheEntry {
  final RouteResult result;
  final DateTime timestamp;
  final LatLng origin;
  final LatLng dest;

  const _CacheEntry({
    required this.result,
    required this.timestamp,
    required this.origin,
    required this.dest,
  });
}
