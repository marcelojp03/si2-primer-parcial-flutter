import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmRoute {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final DateTime eta;

  OsrmRoute({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.eta,
  });
}

class OsrmService {
  static const _baseUrl = 'https://router.project-osrm.org';

  Future<OsrmRoute?> getRoute(LatLng from, LatLng to) async {
    try {
      // OSRM usa longitud,latitud (NO latitud,longitud)
      final url = Uri.parse(
        '$_baseUrl/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );
      final response = await http.get(url, headers: {'Accept': 'application/json'});
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
      return OsrmRoute(
        points: points,
        distanceKm: distM / 1000,
        durationMinutes: (durS / 60).round(),
        eta: DateTime.now().add(Duration(seconds: durS.round())),
      );
    } catch (_) {
      return null;
    }
  }
}
