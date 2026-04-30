import 'package:dio/dio.dart';
import 'package:si2_p1_mobile/core/api/api_client.dart';
import 'package:si2_p1_mobile/core/api/api_exceptions.dart';
import 'package:si2_p1_mobile/core/models/user_model.dart';
import 'package:si2_p1_mobile/core/storage/secure_storage_service.dart';

class AuthService {
  final ApiClient _client = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _client.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      await _storage.saveToken(token);
      // El login solo devuelve el token; obtener perfil por separado
      final meResponse = await _client.get('/users/me');
      return UserModel.fromJson(meResponse.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> register({
    required String fullName,
    required String ci,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      await _client.post(
        '/auth/register',
        data: {
          'full_name': fullName,
          'ci': ci,
          'email': email,
          'password': password,
          'role': 'CLIENTE',
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      // Register devuelve UserRead (sin token); hacer login para obtenerlo
      return await login(email, password);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel?> getProfile() async {
    try {
      final response = await _client.get('/users/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> registerFcmToken(String fcmToken) async {
    try {
      await _client.post('/users/fcm-token', data: {'fcm_token': fcmToken});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<bool> hasToken() async {
    return _storage.hasToken();
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
