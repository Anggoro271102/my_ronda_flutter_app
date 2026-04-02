// File: lib/features/auth/data/models/user_model.dart

class UserModel {
  final int userId;
  final String name;
  final String role;
  final String shift;
  final String employeeId;
  final String email;
  final String department;
  final String assignedPlant;
  final String? avatarUrl;

  UserModel({
    required this.userId,
    required this.name,
    required this.role,
    required this.shift,
    required this.employeeId,
    required this.email,
    required this.department,
    required this.assignedPlant,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'],
      name: json['name'],
      role: json['role'],
      shift: json['shift'],
      employeeId: json['employee_id'],
      email: json['email'],
      department: json['department'],
      assignedPlant: json['assigned_plant'],
      avatarUrl: json['avatar_url'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'role': role,
    'shift': shift,
    'employee_id': employeeId,
    'email': email,
    'department': department,
    'assigned_plant': assignedPlant,
    'avatar_url': avatarUrl,
  };
}
