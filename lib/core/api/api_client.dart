import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:si2_p1_mobile/config/env.dart';
import 'package:si2_p1_mobile/core/storage/secure_storage_service.dart';

class ApiClient {
  late final Dio _dio;
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: Env.connectTimeout,
        receiveTimeout: Env.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    developer.log('🌐 Base URL: ${Env.baseUrl}', name: 'ApiClient');
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService().getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          developer.log(
            '📤 ${options.method} ${options.path}',
            name: 'ApiClient',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log(
            '📥 ${response.statusCode} ${response.requestOptions.path}',
            name: 'ApiClient',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          final status = error.response?.statusCode;
          developer.log(
            '❌ $status ${error.requestOptions.path} — ${error.message}',
            name: 'ApiClient',
          );
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.post<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
  );

  Future<Response<T>> put<T>(String path, {dynamic data, Options? options}) =>
      _dio.put<T>(path, data: data, options: options);

  Future<Response<T>> patch<T>(String path, {dynamic data, Options? options}) =>
      _dio.patch<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(String path, {Options? options}) =>
      _dio.delete<T>(path, options: options);
}
