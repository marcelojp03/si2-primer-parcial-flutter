import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:si2_p1_mobile/core/models/local_incident_model.dart';

/// Repositorio Hive para incidentes pendientes de sincronización (CU30).
class LocalIncidentRepository {
  static const _boxName = 'pending_incidents';

  Future<Box<Map>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<Map>(_boxName);
    }
    return Hive.openBox<Map>(_boxName);
  }

  /// Guarda o actualiza un incidente local. Usa uuid como clave.
  Future<void> save(LocalIncidentModel model) async {
    final box = await _openBox();
    await box.put(model.uuid, model.toMap());
  }

  /// Devuelve todos los incidentes en estado PENDIENTE_SYNC.
  Future<List<LocalIncidentModel>> getPending() async {
    final box = await _openBox();
    return box.values
        .where((m) => m['sync_status'] == 'PENDIENTE_SYNC')
        .map(
          (m) =>
              LocalIncidentModel.fromMap(Map<String, dynamic>.from(m as Map)),
        )
        .toList();
  }

  /// Devuelve todos los incidentes guardados localmente.
  Future<List<LocalIncidentModel>> getAll() async {
    final box = await _openBox();
    return box.values
        .map(
          (m) =>
              LocalIncidentModel.fromMap(Map<String, dynamic>.from(m as Map)),
        )
        .toList();
  }

  /// Marca un incidente como sincronizado con su ID remoto.
  Future<void> markSynced(String uuid, int remoteId) async {
    final box = await _openBox();
    final existing = box.get(uuid);
    if (existing != null) {
      final updated = Map<String, dynamic>.from(existing as Map)
        ..['sync_status'] = 'SYNCED'
        ..['remote_id'] = remoteId;
      await box.put(uuid, updated);
    }
  }

  /// Marca un incidente como error tras fallo de sync.
  Future<void> markError(String uuid) async {
    final box = await _openBox();
    final existing = box.get(uuid);
    if (existing != null) {
      final updated = Map<String, dynamic>.from(existing as Map)
        ..['sync_status'] = 'ERROR';
      await box.put(uuid, updated);
    }
  }

  /// Cantidad de incidentes pendientes de sync.
  Future<int> pendingCount() async {
    final box = await _openBox();
    return box.values.where((m) => m['sync_status'] == 'PENDIENTE_SYNC').length;
  }

  /// Abre el box al iniciar la app (llamar desde main.dart).
  static Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
  }
}

final localIncidentRepositoryProvider = Provider<LocalIncidentRepository>((
  ref,
) {
  return LocalIncidentRepository();
});
