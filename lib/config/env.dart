import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api/v1';

  static Duration get connectTimeout => Duration(
    seconds: int.tryParse(dotenv.env['CONNECT_TIMEOUT'] ?? '60') ?? 60,
  );

  static Duration get receiveTimeout => Duration(
    seconds: int.tryParse(dotenv.env['RECEIVE_TIMEOUT'] ?? '60') ?? 60,
  );

  // Routing providers
  static String get osrmBaseUrl =>
      dotenv.env['OSRM_BASE_URL'] ?? 'https://router.project-osrm.org';

  static String get orsApiKey =>
      dotenv.env['ORS_API_KEY'] ?? '';

  // Claves para SecureStorage
  static const String tokenKey = 'access_token';
  static const String userKey = 'user_data';
}
