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
      orderTime: (data['order_time'] as Timestamp).toDate(),
      pickupTime: data['pickup_time'] != null 
          ? (data['pickup_time'] as Timestamp).toDate() 
          : null,
      note: data['note'],
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
    };
  }
}