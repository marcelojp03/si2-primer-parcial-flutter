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
  final String serviceModality;
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
    this.serviceModality = 'A_DOMICILIO',
    required this.requestedAt,
  });

  bool get isClientGoesToWorkshop => serviceModality == 'CLIENTE_VE_TALLER';
  bool get isAtHome => serviceModality == 'A_DOMICILIO';

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
    serviceModality: json['service_modality'] as String? ?? 'A_DOMICILIO',
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
  final String? quotationStatus;
  final String? quotationDescription;
  final int? estimatedCompletionMinutes;

  const AssignmentModel({
    required this.id,
    required this.incidentId,
    required this.workshopId,
    this.technicianId,
    required this.assignmentStatus,
    this.estimatedCost,
    this.finalCost,
    this.performedServiceDescription,
    this.quotationStatus,
    this.quotationDescription,
    this.estimatedCompletionMinutes,
  });

  bool get canPay =>
      assignmentStatus == 'ATENDIDO' || assignmentStatus == 'PENDIENTE_PAGO';

  bool get canRate => assignmentStatus == 'PAGADO';

  bool get hasPendingQuote => quotationStatus == 'PENDIENTE';
  bool get hasApprovedQuote => quotationStatus == 'APROBADO';
  bool get hasRejectedQuote => quotationStatus == 'RECHAZADO';

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
        quotationStatus: json['quotation_status'] as String?,
        quotationDescription: json['quotation_description'] as String?,
        estimatedCompletionMinutes:
            json['estimated_completion_minutes'] as int?,
      );
}

// ---------------------------------------------------------------------------

class AiAnalysisModel {
  final int id;
  final int incidentId;
  final String? transcribedAudio;
  final String? generatedSummary;
  final String? predictedPriorityLevel;
  final String? visibleDamageDetected;
  final bool? predictedRequiresTow;
  final double? confidenceScore;

  const AiAnalysisModel({
    required this.id, required this.incidentId,
    this.transcribedAudio, this.generatedSummary,
    this.predictedPriorityLevel, this.visibleDamageDetected,
    this.predictedRequiresTow, this.confidenceScore,
  });

  factory AiAnalysisModel.fromJson(Map<String, dynamic> json) => AiAnalysisModel(
    id: json['id'] as int,
    incidentId: json['incident_id'] as int,
    transcribedAudio: json['transcribed_audio'] as String?,
    generatedSummary: json['generated_summary'] as String?,
    predictedPriorityLevel: json['predicted_priority_level'] as String?,
    visibleDamageDetected: json['visible_damage_detected'] as String?,
    predictedRequiresTow: json['predicted_requires_tow'] as bool?,
    confidenceScore: json['confidence_score'] != null ? (json['confidence_score'] as num).toDouble() : null,
  );
}

// ---------------------------------------------------------------------------

class WorkshopCandidateModel {
  final int id;
  final int incidentId;
  final int workshopId;
  final double? score;
  final double? distanceKm;
  final int? estimatedArrivalMinutes;
  final String responseStatus;

  const WorkshopCandidateModel({
    required this.id,
    required this.incidentId,
    required this.workshopId,
    this.score,
    this.distanceKm,
    this.estimatedArrivalMinutes,
    required this.responseStatus,
  });

  bool get isAccepted => responseStatus == 'ACEPTADO';

  factory WorkshopCandidateModel.fromJson(Map<String, dynamic> json) =>
      WorkshopCandidateModel(
        id: json['id'] as int,
        incidentId: json['incident_id'] as int,
        workshopId: json['workshop_id'] as int,
        score: json['score'] != null ? (json['score'] as num).toDouble() : null,
        distanceKm: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
        estimatedArrivalMinutes: json['estimated_arrival_minutes'] as int?,
        responseStatus: json['response_status'] as String? ?? '',
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
