import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'student', 'staff', 'vendor', 'admin'
  final double walletBalance;
  final String? name;
  final String? phoneNumber;
  final String? campusId; // Student/Staff ID or Vendor ID
  final List<String>? favoriteVendors;
  
  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.walletBalance,
    this.name,
    this.phoneNumber,
    this.campusId,
    this.favoriteVendors,
  });
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      walletBalance: (data['wallet_balance'] ?? 0.0).toDouble(),
      name: data['name'],
      phoneNumber: data['phone_number'],
      campusId: data['campus_id'],
      favoriteVendors: data['favorite_vendors'] != null 
          ? List<String>.from(data['favorite_vendors']) 
          : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'wallet_balance': walletBalance,
      'name': name,
      'phone_number': phoneNumber,
      'campus_id': campusId,
      'favorite_vendors': favoriteVendors,
    };
  }
}