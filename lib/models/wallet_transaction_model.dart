import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  topup,
  payment,
  purchase,
  refund
}

class WalletTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final DateTime timestamp;
  final String? orderId; // For payment and refund transactions
  final String? paymentMethod; // For top-up transactions (UPI, Net Banking, etc.)
  final String? transactionReference; // External payment reference
  
  WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.orderId,
    this.paymentMethod,
    this.transactionReference,
  });
  
  factory WalletTransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return WalletTransactionModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['type'] ?? 'topup'}',
        orElse: () => TransactionType.topup,
      ),
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      orderId: data['order_id'],
      paymentMethod: data['payment_method'],
      transactionReference: data['transaction_reference'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'amount': amount,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'order_id': orderId,
      'payment_method': paymentMethod,
      'transaction_reference': transactionReference,
    };
  }
}