class VehicleModel {
  final int id;
  final int userId;
  final String plate;
  final String brand;
  final String model;
  final int manufactureYear;
  final String color;
  final String? notes;
  final String? photoUrl;
  final String status;

  const VehicleModel({
    required this.id,
    required this.userId,
    required this.plate,
    required this.brand,
    required this.model,
    required this.manufactureYear,
    required this.color,
    required this.status,
    this.notes,
    this.photoUrl,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVO';

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
    id: json['id'] as int,
    userId: json['user_id'] as int,
    plate: json['plate'] as String,
    brand: json['brand'] as String,
    model: json['model'] as String,
    manufactureYear: json['manufacture_year'] as int,
    color: json['color'] as String? ?? '',
    notes: json['notes'] as String?,
    photoUrl: json['photo_url'] as String?,
    status: json['status'] as String? ?? 'ACTIVO',
  );

  Map<String, dynamic> toJson() => {
    'plate': plate,
    'brand': brand,
    'model': model,
    'manufacture_year': manufactureYear,
    'color': color,
    'status': status,
    if (notes != null) 'notes': notes,
    if (photoUrl != null) 'photo_url': photoUrl,
  };
}
