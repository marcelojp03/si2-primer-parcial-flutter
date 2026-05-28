import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  /// ID del recurso existente (presente en respuesta 409).
  final int? existingId;

  const ApiException({this.statusCode, required this.message, this.existingId});

  factory ApiException.fromDioError(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    String message;
    int? existingId;

    if (data is Map && data.containsKey('detail')) {
      message = data['detail'].toString();
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Tiempo de conexión agotado. Verifica tu red.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Sin conexión. Verifica tu red.';
    } else {
      message = switch (status) {
        400 => 'Solicitud inválida.',
        401 => 'Sesión expirada. Inicia sesión nuevamente.',
        403 => 'No tienes permiso para realizar esta acción.',
        404 => 'Recurso no encontrado.',
        422 => 'Datos inválidos.',
        500 => 'Error interno del servidor.',
        _ => 'Error inesperado. Intenta nuevamente.',
      };
    }

    // Extraer ID del recurso existente en respuesta 409
    if (status == 409 && data is Map) {
      existingId = data['id'] as int?;
    }

    return ApiException(statusCode: status, message: message, existingId: existingId);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
