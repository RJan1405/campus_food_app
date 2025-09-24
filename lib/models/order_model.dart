import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  placed,
  accepted,
  preparing,
  ready,
  completed,
  cancelled,
  rejected
}

class OrderItemModel {
  final String menuItemId;
  final String name;
  final int quantity;
  final double price;
  final double discountedPrice;
  
  OrderItemModel({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.discountedPrice,
  });
  
  factory OrderItemModel.fromMap(Map<String, dynamic> data) {
    return OrderItemModel(
      menuItemId: data['menu_item_id'] ?? '',
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      discountedPrice: (data['discounted_price'] ?? 0.0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'menu_item_id': menuItemId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'discounted_price': discountedPrice,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String vendorId;
  final String vendorName;
  final List<OrderItemModel> items;
  final double totalAmount;
  final double discountedAmount;
  final double walletSavings;
  final OrderStatus status;
  final DateTime orderTime;
  final DateTime? pickupTime;
  final String? note;
  final String? promotionId;
  final String? rejectionReason;
  final DateTime? acceptedTime;
  final DateTime? preparingTime;
  final DateTime? readyTime;
  final String? pickupLocation;
  final String? estimatedReadyTime;
  final String? cancellationRequestStatus; // 'pending', 'approved', 'rejected', null
  
  OrderModel({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.vendorName,
    required this.items,
    required this.totalAmount,
    required this.discountedAmount,
    required this.walletSavings,
    required this.status,
    required this.orderTime,
    this.pickupTime,
    this.note,
    this.promotionId,
    this.rejectionReason,
    this.acceptedTime,
    this.preparingTime,
    this.readyTime,
    this.pickupLocation,
    this.estimatedReadyTime,
    this.cancellationRequestStatus,
  });
  
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    List<OrderItemModel> orderItems = [];
    if (data['items'] != null) {
      orderItems = List<OrderItemModel>.from(
        (data['items'] as List).map((item) => OrderItemModel.fromMap(item))
      );
    }
    
    return OrderModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      vendorId: data['vendor_id'] ?? '',
      vendorName: data['vendor_name'] ?? '',
      items: orderItems,
      totalAmount: (data['total_amount'] ?? 0.0).toDouble(),
      discountedAmount: (data['discounted_amount'] ?? 0.0).toDouble(),
      walletSavings: (data['wallet_savings'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${data['status'] ?? 'placed'}',
        orElse: () => OrderStatus.placed,
      ),
      orderTime: data['order_time'] != null 
          ? (data['order_time'] as Timestamp).toDate()
          : DateTime.now(),
      pickupTime: data['pickup_time'] != null 
          ? (data['pickup_time'] as Timestamp).toDate() 
          : null,
      note: data['note'],
      promotionId: data['promotion_id'],
      rejectionReason: data['rejection_reason'],
      acceptedTime: data['accepted_time'] != null 
          ? (data['accepted_time'] as Timestamp).toDate() 
          : null,
      preparingTime: data['preparing_time'] != null 
          ? (data['preparing_time'] as Timestamp).toDate() 
          : null,
      readyTime: data['ready_time'] != null 
          ? (data['ready_time'] as Timestamp).toDate() 
          : null,
      pickupLocation: data['pickup_location'],
      estimatedReadyTime: data['estimated_ready_time'],
      cancellationRequestStatus: data['cancellation_request_status'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'items': items.map((item) => item.toMap()).toList(),
      'total_amount': totalAmount,
      'discounted_amount': discountedAmount,
      'wallet_savings': walletSavings,
      'status': status.toString().split('.').last,
      'order_time': Timestamp.fromDate(orderTime),
      'pickup_time': pickupTime != null ? Timestamp.fromDate(pickupTime!) : null,
      'note': note,
      'promotion_id': promotionId,
      'rejection_reason': rejectionReason,
      'accepted_time': acceptedTime != null ? Timestamp.fromDate(acceptedTime!) : null,
      'preparing_time': preparingTime != null ? Timestamp.fromDate(preparingTime!) : null,
      'ready_time': readyTime != null ? Timestamp.fromDate(readyTime!) : null,
      'pickup_location': pickupLocation,
      'estimated_ready_time': estimatedReadyTime,
      'cancellation_request_status': cancellationRequestStatus,
    };
  }

  // Getter for createdAt (alias for orderTime)
  DateTime get createdAt => orderTime;

  // Getter for total (alias for totalAmount)
  double get total => totalAmount;
}