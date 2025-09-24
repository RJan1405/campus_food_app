import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  walletTopUp,
  walletPayment,
  walletRefund,
  orderPayment,
  orderRefund,
  orderCancellation,
}

class TransactionModel {
  final String id;
  final String userId;
  final String? orderId;
  final String? vendorId;
  final String? vendorName;
  final double amount;
  final TransactionType type;
  final String description;
  final DateTime timestamp;
  final String? paymentMethod;
  final String? paymentId;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.userId,
    this.orderId,
    this.vendorId,
    this.vendorName,
    required this.amount,
    required this.type,
    required this.description,
    required this.timestamp,
    this.paymentMethod,
    this.paymentId,
    this.metadata,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      orderId: data['order_id'],
      vendorId: data['vendor_id'],
      vendorName: data['vendor_name'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => TransactionType.walletTopUp,
      ),
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      paymentMethod: data['payment_method'],
      paymentId: data['payment_id'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'order_id': orderId,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'amount': amount,
      'type': type.toString().split('.').last,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'payment_method': paymentMethod,
      'payment_id': paymentId,
      'metadata': metadata,
    };
  }

  String get formattedAmount {
    final sign = amount >= 0 ? '+' : '';
    return '$sign₹${amount.abs().toStringAsFixed(2)}';
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.walletTopUp:
        return 'Wallet Top-up';
      case TransactionType.walletPayment:
        return 'Wallet Payment';
      case TransactionType.walletRefund:
        return 'Wallet Refund';
      case TransactionType.orderPayment:
        return 'Order Payment';
      case TransactionType.orderRefund:
        return 'Order Refund';
      case TransactionType.orderCancellation:
        return 'Order Cancellation';
    }
  }

  bool get isPositive => amount >= 0;
}
