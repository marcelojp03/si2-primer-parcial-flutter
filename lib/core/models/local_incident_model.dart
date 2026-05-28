/// Modelo de incidente guardado localmente (offline) con Hive.
/// Se almacena como Map en un Box<Map> para evitar code generation.
class LocalIncidentModel {
  final String uuid;
  final String title;
  final String? descriptionText;
  final double latitude;
  final double longitude;
  final int vehicleId;
  final bool requiresTow;
  final String? referenceAddress;
  String syncStatus; // PENDIENTE_SYNC | SYNCED | ERROR
  int? remoteId; // ID asignado por el servidor tras sincronizar
  final DateTime createdAt;

  LocalIncidentModel({
    required this.uuid,
    required this.title,
    this.descriptionText,
    required this.latitude,
    required this.longitude,
    required this.vehicleId,
    this.requiresTow = false,
    this.referenceAddress,
    this.syncStatus = 'PENDIENTE_SYNC',
    this.remoteId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'uuid': uuid,
    'title': title,
    'description_text': descriptionText,
    'latitude': latitude,
    'longitude': longitude,
    'vehicle_id': vehicleId,
    'requires_tow': requiresTow,
    'reference_address': referenceAddress,
    'sync_status': syncStatus,
    'remote_id': remoteId,
    'created_at': createdAt.toIso8601String(),
  };

  factory LocalIncidentModel.fromMap(Map<String, dynamic> m) =>
      LocalIncidentModel(
        uuid: m['uuid'] as String,
        title: m['title'] as String,
        descriptionText: m['description_text'] as String?,
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        vehicleId: m['vehicle_id'] as int,
        requiresTow: m['requires_tow'] as bool? ?? false,
        referenceAddress: m['reference_address'] as String?,
        syncStatus: m['sync_status'] as String? ?? 'PENDIENTE_SYNC',
        remoteId: m['remote_id'] as int?,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
