import '../config/env.dart';
import 'routing/routing_service.dart';
import 'routing/osrm_routing_service.dart';
import 'routing/ors_routing_service.dart';
import 'routing/fallback_routing_service.dart';

RoutingService createRoutingService() {
  final providers = <RoutingService>[
    OsrmRoutingService(baseUrl: Env.osrmBaseUrl),
  ];

  final orsKey = Env.orsApiKey;
  if (orsKey.isNotEmpty) {
    providers.add(OrsRoutingService(apiKey: orsKey));
  }

  return FallbackRoutingService(providers: providers);
}
