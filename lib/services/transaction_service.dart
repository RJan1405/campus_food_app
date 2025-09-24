import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Record a transaction
  Future<void> recordTransaction({
    required String userId,
    String? orderId,
    String? vendorId,
    String? vendorName,
    required double amount,
    required TransactionType type,
    required String description,
    String? paymentMethod,
    String? paymentId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final transaction = TransactionModel(
        id: '', // Firestore will generate this
        userId: userId,
        orderId: orderId,
        vendorId: vendorId,
        vendorName: vendorName,
        amount: amount,
        type: type,
        description: description,
        timestamp: DateTime.now(),
        paymentMethod: paymentMethod,
        paymentId: paymentId,
        metadata: metadata,
      );

      await _firestore.collection('transactions').add(transaction.toMap());
      if (kDebugMode) {
        print('Transaction recorded: ${type.name} - ${transaction.formattedAmount} for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording transaction: $e');
      }
      rethrow;
    }
  }

  // Get user's transaction history
  Stream<List<TransactionModel>> getUserTransactionHistory(String userId) {
    return _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          List<TransactionModel> transactions = snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();
          
          // Sort by timestamp in memory to avoid index requirement
          transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          return transactions;
        });
  }

  // Get user's transaction history with pagination
  Future<List<TransactionModel>> getUserTransactionHistoryPaginated(
    String userId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
  }

  // Get transactions by type
  Stream<List<TransactionModel>> getUserTransactionsByType(
    String userId,
    TransactionType type,
  ) {
    return _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('type', isEqualTo: type.toString().split('.').last)
        .snapshots()
        .map((snapshot) {
          List<TransactionModel> transactions = snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();
          
          // Sort by timestamp in memory to avoid index requirement
          transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          return transactions;
        });
  }

  // Get transactions for a specific order
  Future<List<TransactionModel>> getOrderTransactions(String orderId) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('order_id', isEqualTo: orderId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
  }

  // Get transaction summary for user
  Future<Map<String, dynamic>> getUserTransactionSummary(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .get();

      double totalSpent = 0.0;
      double totalReceived = 0.0;
      int totalTransactions = snapshot.docs.length;
      Map<TransactionType, int> typeCounts = {};

      for (var doc in snapshot.docs) {
        final transaction = TransactionModel.fromFirestore(doc);
        
        if (transaction.amount > 0) {
          totalReceived += transaction.amount;
        } else {
          totalSpent += transaction.amount.abs();
        }

        typeCounts[transaction.type] = (typeCounts[transaction.type] ?? 0) + 1;
      }

      return {
        'total_transactions': totalTransactions,
        'total_spent': totalSpent,
        'total_received': totalReceived,
        'type_counts': typeCounts,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting transaction summary: $e');
      }
      return {
        'total_transactions': 0,
        'total_spent': 0.0,
        'total_received': 0.0,
        'type_counts': <TransactionType, int>{},
      };
    }
  }
}
