import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor_wallet_transaction_model.dart';

class VendorWalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get vendor wallet balance
  Future<double> getVendorWalletBalance(String vendorId) async {
    try {
      final vendorDoc = await _firestore.collection('vendors').doc(vendorId).get();
      if (vendorDoc.exists) {
        Map<String, dynamic> data = vendorDoc.data() as Map<String, dynamic>;
        return (data['wallet_balance'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error getting vendor wallet balance: $e');
      return 0.0;
    }
  }

  // Update vendor wallet balance
  Future<bool> updateVendorWalletBalance(String vendorId, double newBalance) async {
    try {
      await _firestore.collection('vendors').doc(vendorId).update({
        'wallet_balance': newBalance,
        'updated_at': FieldValue.serverTimestamp(),
      });
      print('Vendor wallet balance updated to ₹$newBalance for vendor: $vendorId');
      return true;
    } catch (e) {
      print('Error updating vendor wallet balance: $e');
      return false;
    }
  }

  // Record a vendor wallet transaction
  Future<void> recordVendorTransaction({
    required String vendorId,
    required double amount,
    required VendorTransactionType type,
    String? orderId,
    String? customerId,
    String? description,
    String? transactionReference,
  }) async {
    try {
      final transaction = VendorWalletTransactionModel(
        id: '', // Firestore will generate this
        vendorId: vendorId,
        amount: amount,
        type: type,
        timestamp: DateTime.now(),
        orderId: orderId,
        customerId: customerId,
        description: description,
        transactionReference: transactionReference,
      );
      
      await _firestore.collection('vendor_wallet_transactions').add(transaction.toMap());
      print('Vendor transaction recorded: ${type.name} - ₹$amount for vendor: $vendorId');
    } catch (e) {
      print('Error recording vendor transaction: $e');
      rethrow;
    }
  }

  // Process order payment to vendor
  Future<bool> processOrderPayment({
    required String vendorId,
    required double amount,
    required String orderId,
    required String customerId,
  }) async {
    try {
      final currentBalance = await getVendorWalletBalance(vendorId);
      final newBalance = currentBalance + amount;
      final success = await updateVendorWalletBalance(vendorId, newBalance);
      
      if (success) {
        // Record the transaction
        await recordVendorTransaction(
          vendorId: vendorId,
          amount: amount,
          type: VendorTransactionType.orderPayment,
          orderId: orderId,
          customerId: customerId,
          description: 'Payment received for order #${orderId.substring(0, 8)}',
        );
      }
      
      return success;
    } catch (e) {
      print('Error processing order payment: $e');
      return false;
    }
  }

  // Process refund from vendor to customer
  Future<bool> processRefund({
    required String vendorId,
    required double amount,
    required String orderId,
    required String customerId,
  }) async {
    try {
      final currentBalance = await getVendorWalletBalance(vendorId);
      if (currentBalance < amount) {
        print('Insufficient vendor balance for refund');
        return false;
      }
      
      final newBalance = currentBalance - amount;
      final success = await updateVendorWalletBalance(vendorId, newBalance);
      
      if (success) {
        // Record the transaction
        await recordVendorTransaction(
          vendorId: vendorId,
          amount: -amount, // Negative for debit
          type: VendorTransactionType.refund,
          orderId: orderId,
          customerId: customerId,
          description: 'Refund processed for order #${orderId.substring(0, 8)}',
        );
      }
      
      return success;
    } catch (e) {
      print('Error processing refund: $e');
      return false;
    }
  }

  // Get vendor transaction history
  Future<List<VendorWalletTransactionModel>> getVendorTransactionHistory(String vendorId) async {
    try {
      // Get all transactions for the vendor and sort in memory to avoid index requirements
      final snapshot = await _firestore
          .collection('vendor_wallet_transactions')
          .where('vendor_id', isEqualTo: vendorId)
          .get();
      
      List<VendorWalletTransactionModel> transactions = snapshot.docs
          .map((doc) => VendorWalletTransactionModel.fromFirestore(doc))
          .toList();
      
      // Sort by timestamp in descending order
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Return only the latest 50 transactions
      return transactions.take(50).toList();
    } catch (e) {
      print('Error getting vendor transaction history: $e');
      return [];
    }
  }

  // Get vendor earnings summary
  Future<Map<String, dynamic>> getVendorEarningsSummary(String vendorId) async {
    try {
      final transactions = await getVendorTransactionHistory(vendorId);
      
      double totalEarnings = 0.0;
      double totalRefunds = 0.0;
      int totalOrders = 0;
      
      for (var transaction in transactions) {
        if (transaction.type == VendorTransactionType.orderPayment) {
          totalEarnings += transaction.amount;
          totalOrders++;
        } else if (transaction.type == VendorTransactionType.refund) {
          totalRefunds += transaction.amount.abs();
        }
      }
      
      return {
        'total_earnings': totalEarnings,
        'total_refunds': totalRefunds,
        'net_earnings': totalEarnings - totalRefunds,
        'total_orders': totalOrders,
        'current_balance': await getVendorWalletBalance(vendorId),
      };
    } catch (e) {
      print('Error getting vendor earnings summary: $e');
      return {
        'total_earnings': 0.0,
        'total_refunds': 0.0,
        'net_earnings': 0.0,
        'total_orders': 0,
        'current_balance': 0.0,
      };
    }
  }
}
