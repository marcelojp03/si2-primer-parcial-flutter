import 'package:dio/dio.dart';
import 'package:si2_p1_mobile/core/api/api_client.dart';
import 'package:si2_p1_mobile/core/api/api_exceptions.dart';
import 'package:si2_p1_mobile/core/models/vehicle_model.dart';

class VehicleService {
  final ApiClient _client = ApiClient();

  Future<List<VehicleModel>> getMyVehicles(int userId) async {
    try {
      final response = await _client.get(
        '/vehicles',
        queryParameters: {'user_id': userId},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<VehicleModel> createVehicle({
    required int userId,
    required String plate,
    required String brand,
    required String model,
    required int manufactureYear,
    required String color,
  }) async {
    try {
      final response = await _client.post(
        '/vehicles',
        data: {
          'user_id': userId,
          'plate': plate,
          'brand': brand,
          'model': model,
          'manufacture_year': manufactureYear,
          'color': color,
        },
      );
      return VehicleModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<VehicleModel> updateVehicle(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client.put('/vehicles/$id', data: data);
      return VehicleModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteVehicle(int id) async {
    try {
      await _client.delete('/vehicles/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
