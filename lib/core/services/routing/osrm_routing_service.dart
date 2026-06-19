import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';
import 'route_result.dart';

/// Provider de routing usando OSRM público o self-hosted.
///
/// ⚠ LÍMITES DEL SERVIDOR PÚBLICO (router.project-osrm.org):
///   - No comercial, demo only
///   - Máximo ~1 request/segundo
///   - Sin garantía de uptime ni latencia
///
/// Para producción se recomienda:
///   1. Montar OSRM propio con Docker + extracto OSM de Bolivia
///   2. O usar proveedor comercial (Google Routes, Mapbox, GraphHopper)
///   3. O al menos enrutar a través del backend FastAPI como proxy
///
/// La URL base se configura desde .env → OSRM_BASE_URL.
class OsrmRoutingService extends RoutingService {
  final String baseUrl;
  final Duration timeout;

  OsrmRoutingService({
    this.baseUrl = 'https://router.project-osrm.org',
    this.timeout = const Duration(seconds: 5),
  });

  @override
  Future<RouteResult?> getRoute(LatLng origin, LatLng destination) async {
    final client = http.Client();
    try {
      final url = Uri.parse(
        '$baseUrl/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );
      final response = await client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(timeout);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;
      final route = (data['routes'] as List).first;
      final coords = route['geometry']['coordinates'] as List;
      final points = coords.map<LatLng>((c) {
        return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
      }).toList();
      final distM = (route['distance'] as num).toDouble();
      final durS = (route['duration'] as num).toDouble();
      return RouteResult(
        points: points,
        distanceKm: distM / 1000,
        durationMinutes: (durS / 60).round(),
        eta: DateTime.now().add(Duration(seconds: durS.round())),
        provider: 'osrm',
      );
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}
