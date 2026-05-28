import 'package:dio/dio.dart';
import 'package:si2_p1_mobile/core/api/api_client.dart';
import 'package:si2_p1_mobile/core/api/api_exceptions.dart';
import 'package:si2_p1_mobile/core/models/incident_model.dart';
import 'package:si2_p1_mobile/core/models/local_incident_model.dart';

class IncidentService {
  final ApiClient _client = ApiClient();

  Future<IncidentModel> createIncident({
    required int clientUserId,
    required int vehicleId,
    required String title,
    required String descriptionText,
    required double latitude,
    required double longitude,
    bool requiresTow = false,
    String? referenceAddress,
    String? uuidCliente,
  }) async {
    try {
      final response = await _client.post(
        '/incidents',
        data: {
          'client_user_id': clientUserId,
          'vehicle_id': vehicleId,
          'title': title,
          'description_text': descriptionText,
          'latitude': latitude,
          'longitude': longitude,
          'requires_tow': requiresTow,
          if (referenceAddress != null) 'reference_address': referenceAddress,
          if (uuidCliente != null) 'uuid_cliente': uuidCliente,
        },
      );
      return IncidentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Crea un incidente desde un borrador local (CU31 — sync offline).
  /// Si el servidor responde 409, retorna el incidente existente (idempotencia).
  Future<IncidentModel> createIncidentWithUuid(LocalIncidentModel local) async {
    try {
      final response = await _client.post(
        '/incidents',
        data: {
          'vehicle_id': local.vehicleId,
          'title': local.title,
          if (local.descriptionText != null)
            'description_text': local.descriptionText,
          'latitude': local.latitude,
          'longitude': local.longitude,
          'requires_tow': local.requiresTow,
          if (local.referenceAddress != null)
            'reference_address': local.referenceAddress,
          'uuid_cliente': local.uuid,
        },
      );
      return IncidentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final ex = ApiException.fromDioError(e);
      // 409 = ya existe — el backend devuelve el incidente existente
      if (ex.statusCode == 409) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return IncidentModel.fromJson(data);
        }
      }
      throw ex;
    }
  }

  Future<IncidentModel> getIncident(int id) async {
    try {
      final response = await _client.get('/incidents/$id');
      return IncidentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<IncidentModel>> getMyIncidents(int clientUserId) async {
    try {
      final response = await _client.get(
        '/incidents',
        queryParameters: {'client_user_id': clientUserId},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => IncidentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> uploadEvidence(
    int incidentId,
    String filePath,
    String evidenceType,
  ) async {
    try {
      final formData = FormData.fromMap({
        'incident_id': incidentId.toString(),
        'evidence_type': evidenceType,
        'file': await MultipartFile.fromFile(filePath),
      });
      await _client.post(
        '/incident-evidences',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> analyzeIncident(int incidentId) async {
    try {
      await _client.post('/ai-analysis/$incidentId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AssignmentModel?> getAssignment(int incidentId) async {
    try {
      final response = await _client.get('/assignments/$incidentId');
      return AssignmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> rateService({
    required int serviceAssignmentId,
    required int clientUserId,
    required int score,
    String? comment,
  }) async {
    try {
      await _client.post(
        '/ratings',
        data: {
          'service_assignment_id': serviceAssignmentId,
          'client_user_id': clientUserId,
          'score': score,
          if (comment != null) 'comment': comment,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PaymentModel> makePayment({
    required int serviceAssignmentId,
    required int clientUserId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final response = await _client.post(
        '/payments',
        data: {
          'service_assignment_id': serviceAssignmentId,
          'client_user_id': clientUserId,
          'amount': amount,
          'payment_method': paymentMethod,
        },
      );
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<QRGenerateResponse> generateQR(
    int paymentId, {
    String gloss = 'Auxilio Mecánico',
  }) async {
    try {
      final response = await _client.post(
        '/payments/$paymentId/generate-qr',
        data: {'gloss': gloss, 'additional_data': 'Servicio Auxilio Mecánico'},
      );
      return QRGenerateResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<QRStatusResponse> checkQRStatus(int paymentId) async {
    try {
      final response = await _client.get('/payments/$paymentId/qr-status');
      return QRStatusResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<WorkshopModel?> getWorkshop(int workshopId) async {
    try {
      final response = await _client.get('/workshops/$workshopId');
      return WorkshopModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioError(e);
    }
  }
}
