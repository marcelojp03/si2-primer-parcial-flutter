class IncidentModel {
  final int id;
  final int clientUserId;
  final int vehicleId;
  final int? incidentTypeId;
  final int incidentStatusId;
  final String title;
  final String? descriptionText;
  final String? referenceAddress;
  final double latitude;
  final double longitude;
  final String? priorityLevel;
  final bool requiresTow;
  final String requestedAt;

  const IncidentModel({
    required this.id,
    required this.clientUserId,
    required this.vehicleId,
    this.incidentTypeId,
    required this.incidentStatusId,
    required this.title,
    this.descriptionText,
    this.referenceAddress,
    required this.latitude,
    required this.longitude,
    this.priorityLevel,
    required this.requiresTow,
    required this.requestedAt,
  });

  /// Nombre aproximado del estado basado en el ID (según datos sembrados).
  String get statusLabel {
    const map = {
      1: 'PENDIENTE',
      2: 'NOTIFICADO',
      3: 'ACEPTADO',
      4: 'EN_PROCESO',
      5: 'ATENDIDO',
      6: 'PENDIENTE_PAGO',
      7: 'PAGADO',
      8: 'CANCELADO',
    };
    return map[incidentStatusId] ?? 'PENDIENTE';
  }

  factory IncidentModel.fromJson(Map<String, dynamic> json) => IncidentModel(
    id: json['id'] as int,
    clientUserId: json['client_user_id'] as int,
    vehicleId: json['vehicle_id'] as int,
    incidentTypeId: json['incident_type_id'] as int?,
    incidentStatusId: json['incident_status_id'] as int,
    title: json['title'] as String,
    descriptionText: json['description_text'] as String?,
    referenceAddress: json['reference_address'] as String?,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    priorityLevel: json['priority_level'] as String?,
    requiresTow: json['requires_tow'] as bool? ?? false,
    requestedAt: json['requested_at'] as String? ?? '',
  );
}

class AssignmentModel {
  final int id;
  final int incidentId;
  final int workshopId;
  final int? technicianId;
  final String assignmentStatus;
  final double? estimatedCost;
  final double? finalCost;
  final String? performedServiceDescription;

  const AssignmentModel({
    required this.id,
    required this.incidentId,
    required this.workshopId,
    this.technicianId,
    required this.assignmentStatus,
    this.estimatedCost,
    this.finalCost,
    this.performedServiceDescription,
  });

  bool get canPay =>
      assignmentStatus == 'ATENDIDO' || assignmentStatus == 'PENDIENTE_PAGO';

  bool get canRate => assignmentStatus == 'PAGADO';

  factory AssignmentModel.fromJson(Map<String, dynamic> json) =>
      AssignmentModel(
        id: json['id'] as int,
        incidentId: json['incident_id'] as int,
        workshopId: json['workshop_id'] as int,
        technicianId: json['technician_id'] as int?,
        assignmentStatus: json['assignment_status'] as String,
        estimatedCost: json['estimated_cost'] != null
            ? (json['estimated_cost'] as num).toDouble()
            : null,
        finalCost: json['final_cost'] != null
            ? (json['final_cost'] as num).toDouble()
            : null,
        performedServiceDescription:
            json['performed_service_description'] as String?,
      );
}

// ---------------------------------------------------------------------------

class WorkshopModel {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final bool hasTow;

  const WorkshopModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.hasTow = false,
  });

  factory WorkshopModel.fromJson(Map<String, dynamic> json) => WorkshopModel(
    id: json['id'] as int,
    name: json['name'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    address: json['address'] as String?,
    hasTow: json['has_tow'] as bool? ?? false,
  );
}

// ---------------------------------------------------------------------------

class PaymentModel {
  final int id;
  final int serviceAssignmentId;
  final int clientUserId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;

  const PaymentModel({
    required this.id,
    required this.serviceAssignmentId,
    required this.clientUserId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    id: json['id'] as int,
    serviceAssignmentId: json['service_assignment_id'] as int,
    clientUserId: json['client_user_id'] as int,
    amount: (json['amount'] as num).toDouble(),
    currency: json['currency'] as String? ?? 'BOB',
    paymentMethod: json['payment_method'] as String,
    paymentStatus: json['payment_status'] as String,
  );
}

// ---------------------------------------------------------------------------

class QRGenerateResponse {
  final int paymentId;
  final String idQr;
  final String qrBase64;

  const QRGenerateResponse({
    required this.paymentId,
    required this.idQr,
    required this.qrBase64,
  });

  factory QRGenerateResponse.fromJson(Map<String, dynamic> json) =>
      QRGenerateResponse(
        paymentId: json['payment_id'] as int,
        idQr: json['id_qr'] as String,
        qrBase64: json['qr_base64'] as String,
      );
}

// ---------------------------------------------------------------------------

class QRStatusResponse {
  final int paymentId;
  final String idQr;
  final String vpayStatus;
  final bool paid;

  const QRStatusResponse({
    required this.paymentId,
    required this.idQr,
    required this.vpayStatus,
    required this.paid,
  });

  factory QRStatusResponse.fromJson(Map<String, dynamic> json) =>
      QRStatusResponse(
        paymentId: json['payment_id'] as int,
        idQr: json['id_qr'] as String,
        vpayStatus: json['vpay_status'] as String,
        paid: json['paid'] as bool,
      );
}
