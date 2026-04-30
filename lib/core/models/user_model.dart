class UserModel {
  final int id;
  final String fullName;
  final String? ci;
  final String? phone;
  final String email;
  final String role;
  final String status;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.ci,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as int,
    fullName: json['full_name'] as String,
    email: json['email'] as String,
    role: json['role'] as String? ?? 'CLIENTE',
    status: json['status'] as String? ?? 'ACTIVO',
    ci: json['ci'] as String?,
    phone: json['phone'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'role': role,
    'status': status,
    if (ci != null) 'ci': ci,
    if (phone != null) 'phone': phone,
  };
}
