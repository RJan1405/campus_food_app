import 'package:cloud_firestore/cloud_firestore.dart';

class PickupSlotModel {
  final String id;
  final String vendorId;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final List<String> currentOrders; // Changed from int to List<String>
  final bool isActive;
  
  PickupSlotModel({
    required this.id,
    required this.vendorId,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.currentOrders,
    required this.isActive,
  });
  
  // Add a copyWith method
  PickupSlotModel copyWith({
    String? id,
    String? vendorId,
    DateTime? startTime,
    DateTime? endTime,
    int? capacity,
    List<String>? currentOrders,
    bool? isActive,
  }) {
    return PickupSlotModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      capacity: capacity ?? this.capacity,
      currentOrders: currentOrders ?? this.currentOrders,
      isActive: isActive ?? this.isActive,
    );
  }
}