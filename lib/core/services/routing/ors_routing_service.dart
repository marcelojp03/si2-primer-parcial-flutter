import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';
import 'route_result.dart';

/// Provider de routing usando OpenRouteService (ORS).
///
/// Requiere API key configurada en .env → ORS_API_KEY.
///
/// ⚠ ORS_API_KEY VA EN EL FRONTEND sólo para desarrollo/demo.
/// En producción la API key debe ir del lado del servidor (FastAPI proxy).
///
/// Plan gratuito ORS: ~2000 requests/día, 40/minuto.
/// Para uso intensivo se recomienda plan pago o migrar a OSRM propio.
class OrsRoutingService extends RoutingService {
  final String apiKey;
  final String baseUrl;
  final Duration timeout;

  OrsRoutingService({
    required this.apiKey,
    this.baseUrl = 'https://api.openrouteservice.org',
    this.timeout = const Duration(seconds: 5),
  });

  @override
  Future<RouteResult?> getRoute(LatLng origin, LatLng destination) async {
    if (apiKey.isEmpty) return null;
    final client = http.Client();
    try {
      final url = Uri.parse('$baseUrl/v2/directions/driving-car/geojson');
      final body = jsonEncode({
        'coordinates': [
          [origin.longitude, origin.latitude],
          [destination.longitude, destination.latitude],
        ],
      });
      final response = await client
          .post(
            url,
            headers: {
              'Authorization': apiKey,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List?;
      if (features == null || features.isEmpty) return null;
      final feature = features.first as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      final props = feature['properties'] as Map<String, dynamic>?;
      final summary = props?['summary'] as Map<String, dynamic>?;
      if (geometry == null || summary == null) return null;
      final coords = geometry['coordinates'] as List;
      final points = coords.map<LatLng>((c) {
        return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
      }).toList();
      final distM = (summary['distance'] as num).toDouble();
      final durS = (summary['duration'] as num).toDouble();
      return RouteResult(
        points: points,
        distanceKm: distM / 1000,
        durationMinutes: (durS / 60).round(),
        eta: DateTime.now().add(Duration(seconds: durS.round())),
        provider: 'ors',
      );
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}
