import 'package:cloud_firestore/cloud_firestore.dart';

enum VendorTransactionType {
  orderPayment, // Money received from order
  refund, // Money refunded to customer
  withdrawal, // Vendor withdraws money
  adjustment, // Admin adjustment
}

class VendorWalletTransactionModel {
  final String id;
  final String vendorId;
  final double amount;
  final VendorTransactionType type;
  final DateTime timestamp;
  final String? orderId;
  final String? customerId;
  final String? description;
  final String? transactionReference;

  VendorWalletTransactionModel({
    required this.id,
    required this.vendorId,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.orderId,
    this.customerId,
    this.description,
    this.transactionReference,
  });

  factory VendorWalletTransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return VendorWalletTransactionModel(
      id: doc.id,
      vendorId: data['vendor_id'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: VendorTransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] ?? 'orderPayment'),
        orElse: () => VendorTransactionType.orderPayment,
      ),
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      orderId: data['order_id'],
      customerId: data['customer_id'],
      description: data['description'],
      transactionReference: data['transaction_reference'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendor_id': vendorId,
      'amount': amount,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'order_id': orderId,
      'customer_id': customerId,
      'description': description,
      'transaction_reference': transactionReference,
    };
  }
}
