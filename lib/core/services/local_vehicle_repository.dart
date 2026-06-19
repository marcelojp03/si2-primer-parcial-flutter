import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:si2_p1_mobile/core/models/vehicle_model.dart';

class LocalVehicleRepository {
  static const _boxName = 'local_vehicles';

  Future<Box<Map>> get _box async => await Hive.openBox<Map>(_boxName);

  Future<void> saveAll(List<VehicleModel> vehicles) async {
    final box = await _box;
    await box.clear();
    for (final v in vehicles) {
      await box.put(v.id, v.toJson());
    }
  }

  Future<List<VehicleModel>> getAll() async {
    final box = await _box;
    return box.values.map((m) => VehicleModel.fromJson(Map<String, dynamic>.from(m))).toList();
  }

  Future<VehicleModel?> getById(int id) async {
    final box = await _box;
    final data = box.get(id);
    if (data == null) return null;
    return VehicleModel.fromJson(Map<String, dynamic>.from(data as Map));
  }
}

final localVehicleRepositoryProvider = Provider<LocalVehicleRepository>((ref) {
  return LocalVehicleRepository();
});
