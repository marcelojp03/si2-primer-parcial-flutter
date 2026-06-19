import 'dart:async';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:si2_p1_mobile/core/api/api_exceptions.dart';
import 'package:si2_p1_mobile/core/services/incident_service.dart';
import 'package:si2_p1_mobile/core/services/local_incident_repository.dart';

/// Servicio de sincronización CU31.
/// Escucha cambios de conectividad y procesa incidentes PENDIENTE_SYNC.
class SyncService {
  final LocalIncidentRepository _repo;
  final IncidentService _incidentService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  SyncService(this._repo, this._incidentService);

  void startListening() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      if (hasNet) {
        developer.log(
          '🌐 Net recovered — syncing pending',
          name: 'SyncService',
        );
        syncPending();
      }
    });
    developer.log(
      '👂 SyncService listening for connectivity',
      name: 'SyncService',
    );
  }

  /// Procesa todos los incidentes PENDIENTE_SYNC contra el servidor.
  Future<int> syncPending() async {
    final pending = await _repo.getPending();
    if (pending.isEmpty) return 0;

    int synced = 0;
    for (final local in pending) {
      try {
        final incident = await _incidentService.createIncidentWithUuid(local);
        await _repo.markSynced(local.uuid, incident.id);
        synced++;
        developer.log(
          '✅ Synced ${local.uuid} → remote #${incident.id}',
          name: 'SyncService',
        );
      } on ApiException catch (e) {
        if (e.statusCode == 409) {
          // Idempotencia: ya existe en el servidor — extraer ID de la respuesta
          final remoteId = e.existingId ?? 0;
          await _repo.markSynced(local.uuid, remoteId);
          synced++;
          developer.log(
            '✅ Idempotent 409 for ${local.uuid} — marked synced',
            name: 'SyncService',
          );
        } else {
          await _repo.markError(local.uuid);
          developer.log(
            '❌ Sync failed for ${local.uuid}: ${e.message}',
            name: 'SyncService',
          );
        }
      } catch (e) {
        await _repo.markError(local.uuid);
        developer.log(
          '❌ Sync error for ${local.uuid}: $e',
          name: 'SyncService',
        );
      }
    }
    return synced;
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final repo = ref.read(localIncidentRepositoryProvider);
  final service = IncidentService();
  final syncService = SyncService(repo, service);
  ref.onDispose(syncService.dispose);
  return syncService;
});

/// Provider reactivo que expone la cantidad de incidentes pendientes.
final pendingIncidentsCountProvider = StreamProvider.autoDispose<int>((
  ref,
) async* {
  final repo = ref.read(localIncidentRepositoryProvider);
  // Emitir valor inicial
  yield await repo.pendingCount();

  // Refrescar cada vez que haya un cambio de conectividad
  await for (final _ in Connectivity().onConnectivityChanged) {
    yield await repo.pendingCount();
  }
});
