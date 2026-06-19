import 'package:latlong2/latlong.dart';
import 'route_result.dart';

abstract class RoutingService {
  Future<RouteResult?> getRoute(LatLng origin, LatLng destination);
}
