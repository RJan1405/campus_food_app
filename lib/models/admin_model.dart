import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'super_admin', 'admin'
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  AdminModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return AdminModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'admin',
      permissions: List<String>.from(data['permissions'] ?? []),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'permissions': permissions,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_active': isActive,
    };
  }

  AdminModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}