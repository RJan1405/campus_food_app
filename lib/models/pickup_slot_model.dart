
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

  // Factory method to create from Firestore document
  factory PickupSlotModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PickupSlotModel(
      id: doc.id,
      vendorId: data['vendor_id'] ?? '',
      startTime: (data['start_time'] as Timestamp).toDate(),
      endTime: (data['end_time'] as Timestamp).toDate(),
      capacity: data['capacity'] ?? 0,
      currentOrders: List<String>.from(data['current_orders'] ?? []),
      isActive: data['is_active'] ?? false,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'vendor_id': vendorId,
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'capacity': capacity,
      'current_orders': currentOrders,
      'is_active': isActive,
    };
  }

  // Check if slot is full
  bool get isFull => currentOrders.length >= capacity;

  // Check if slot is available
  bool get isAvailable => isActive && !isFull;

  // Add order to slot
  PickupSlotModel addOrder(String orderId) {
    if (isFull) return this;
    return copyWith(
      currentOrders: [...currentOrders, orderId],
    );
  }

  // Remove order from slot
  PickupSlotModel removeOrder(String orderId) {
    return copyWith(
      currentOrders: currentOrders.where((id) => id != orderId).toList(),
    );
  }
}