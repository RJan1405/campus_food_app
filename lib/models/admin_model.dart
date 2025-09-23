import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminRole {
  superAdmin,
  vendorManager,
  financeManager,
  supportManager
}

class AdminModel {
  final String id;
  final String userId; // Reference to user ID
  final String name;
  final String email;
  final AdminRole role;
  final List<String> permissions; // Specific permissions
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;
  
  AdminModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
    required this.createdAt,
    required this.lastLogin,
    required this.isActive,
  });
  
  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AdminModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: AdminRole.values.firstWhere(
        (e) => e.toString() == 'AdminRole.${data['role'] ?? 'supportManager'}',
        orElse: () => AdminRole.supportManager,
      ),
      permissions: data['permissions'] != null 
          ? List<String>.from(data['permissions']) 
          : [],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      lastLogin: (data['last_login'] as Timestamp).toDate(),
      isActive: data['is_active'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'permissions': permissions,
      'created_at': Timestamp.fromDate(createdAt),
      'last_login': Timestamp.fromDate(lastLogin),
      'is_active': isActive,
    };
  }
  
  // Check if admin has a specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
  
  // Update last login time
  AdminModel updateLastLogin() {
    return AdminModel(
      id: id,
      userId: userId,
      name: name,
      email: email,
      role: role,
      permissions: permissions,
      createdAt: createdAt,
      lastLogin: DateTime.now(),
      isActive: isActive,
    );
  }
  
  // Add a permission
  AdminModel addPermission(String permission) {
    if (permissions.contains(permission)) {
      return this;
    }
    
    List<String> updatedPermissions = List.from(permissions);
    updatedPermissions.add(permission);
    
    return AdminModel(
      id: id,
      userId: userId,
      name: name,
      email: email,
      role: role,
      permissions: updatedPermissions,
      createdAt: createdAt,
      lastLogin: lastLogin,
      isActive: isActive,
    );
  }
  
  // Remove a permission
  AdminModel removePermission(String permission) {
    if (!permissions.contains(permission)) {
      return this;
    }
    
    List<String> updatedPermissions = List.from(permissions);
    updatedPermissions.remove(permission);
    
    return AdminModel(
      id: id,
      userId: userId,
      name: name,
      email: email,
      role: role,
      permissions: updatedPermissions,
      createdAt: createdAt,
      lastLogin: lastLogin,
      isActive: isActive,
    );
  }
  
  // Change admin role
  AdminModel changeRole(AdminRole newRole) {
    return AdminModel(
      id: id,
      userId: userId,
      name: name,
      email: email,
      role: newRole,
      permissions: permissions,
      createdAt: createdAt,
      lastLogin: lastLogin,
      isActive: isActive,
    );
  }
  
  // Toggle active status
  AdminModel toggleActive() {
    return AdminModel(
      id: id,
      userId: userId,
      name: name,
      email: email,
      role: role,
      permissions: permissions,
      createdAt: createdAt,
      lastLogin: lastLogin,
      isActive: !isActive,
    );
  }
}