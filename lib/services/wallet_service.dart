import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_food_app/models/wallet_transaction_model.dart';
import 'package:campus_food_app/models/transaction_model.dart' as general;
import 'package:campus_food_app/services/payment_service.dart';
import 'package:campus_food_app/services/transaction_service.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PaymentService _paymentService = PaymentService();
  final TransactionService _transactionService = TransactionService();
  
  // Get current wallet balance
  Future<double> getWalletBalance() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      return data != null ? (data['wallet_balance'] ?? 0.0).toDouble() : 0.0;
    } catch (e) {
      print('Error getting wallet balance: $e');
      return 0.0;
    }
  }
  
  // Update wallet balance
  Future<bool> updateWalletBalance(double newBalance) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      await _firestore.collection('users').doc(user.uid).update({
        'wallet_balance': newBalance,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('Wallet balance updated to: ₹$newBalance for user: ${user.uid}');
      return true;
    } catch (e) {
      print('Error updating wallet balance: $e');
      return false;
    }
  }
  
  // Add money to wallet
  Future<void> topUpWallet(double amount, Function onSuccess, Function onError) async {
    _paymentService.initListeners(
      (dynamic response) async {
        try {
          // On successful payment, update wallet balance
          final currentBalance = await getWalletBalance();
          final newBalance = currentBalance + amount;
          final success = await updateWalletBalance(newBalance);
          
          if (success) {
            // Record the transaction in both wallet and general transaction history
            await recordTransaction(
              amount: amount,
              type: TransactionType.topup,
              paymentMethod: 'Razorpay',
              transactionReference: response.paymentId ?? 'unknown',
            );
            
            // Also record in general transaction history
            await _transactionService.recordTransaction(
              userId: _auth.currentUser!.uid,
              amount: amount,
              type: general.TransactionType.walletTopUp,
              description: 'Wallet top-up via Razorpay',
              paymentMethod: 'Razorpay',
              paymentId: response.paymentId,
            );
            
            onSuccess(response);
          } else {
            onError('Failed to update wallet balance');
          }
        } catch (e) {
          onError('Error processing wallet top-up: $e');
        }
      },
      (dynamic response) {
        onError('Payment failed: ${response.message ?? 'Unknown error'}');
      },
    );
    
    // Open Razorpay checkout
    await _paymentService.openCheckout(amount);
  }
  
  // Record a wallet transaction
  Future<void> recordTransaction({
    required double amount,
    required TransactionType type,
    String? orderId,
    String? paymentMethod,
    String? transactionReference,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final transaction = WalletTransactionModel(
        id: '', // Firestore will generate this
        userId: user.uid,
        amount: amount,
        type: type,
        timestamp: DateTime.now(),
        orderId: orderId,
        paymentMethod: paymentMethod,
        transactionReference: transactionReference,
      );
      
      await _firestore.collection('wallet_transactions').add(transaction.toMap());
      print('Transaction recorded: ${type.name} - ₹$amount for user: ${user.uid}');
    } catch (e) {
      print('Error recording transaction: $e');
      rethrow;
    }
  }
  
  // Get wallet transaction history
  Future<List<WalletTransactionModel>> getTransactionHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      
      // Get all transactions for the user and sort in memory to avoid index requirements
      final snapshot = await _firestore
          .collection('wallet_transactions')
          .where('user_id', isEqualTo: user.uid)
          .get();
      
      List<WalletTransactionModel> transactions = snapshot.docs
          .map((doc) => WalletTransactionModel.fromFirestore(doc))
          .toList();
      
      // Sort by timestamp in descending order
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Return only the latest 20 transactions
      return transactions.take(20).toList();
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }
  
  // Process payment from wallet
  Future<bool> processPayment({
    required String userId,
    required double amount,
    required String orderId,
  }) async {
    try {
      final currentBalance = await getWalletBalance();
      if (currentBalance < amount) {
        return false; // Insufficient balance
      }
      
      final newBalance = currentBalance - amount;
      final success = await updateWalletBalance(newBalance);
      
      if (success) {
        // Record the transaction in wallet history
        await recordTransaction(
          amount: -amount, // Negative for debit
          type: TransactionType.purchase,
          orderId: orderId,
          paymentMethod: 'Wallet',
        );
        
        // Also record in general transaction history
        await _transactionService.recordTransaction(
          userId: userId,
          orderId: orderId,
          amount: -amount,
          type: general.TransactionType.walletPayment,
          description: 'Payment from wallet for order',
          paymentMethod: 'wallet',
        );
      }
      
      return success;
    } catch (e) {
      print('Error processing payment: $e');
      return false;
    }
  }

  // Process refund to wallet
  Future<bool> processRefund({
    required String userId,
    required double amount,
    required String orderId,
  }) async {
    try {
      final currentBalance = await getWalletBalance();
      final newBalance = currentBalance + amount;
      final success = await updateWalletBalance(newBalance);
      
      if (success) {
        // Record the transaction in wallet history
        await recordTransaction(
          amount: amount,
          type: TransactionType.refund,
          orderId: orderId,
          paymentMethod: 'Wallet',
        );
        
        // Also record in general transaction history
        await _transactionService.recordTransaction(
          userId: userId,
          orderId: orderId,
          amount: amount,
          type: general.TransactionType.walletRefund,
          description: 'Refund to wallet for order',
          paymentMethod: 'wallet',
        );
      }
      
      return success;
    } catch (e) {
      print('Error processing refund: $e');
      return false;
    }
  }

  // Update transaction order ID (for wallet payments)
  Future<void> updateTransactionOrderId(String tempOrderId, String actualOrderId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Find and update the transaction with the temporary order ID
      final querySnapshot = await _firestore
          .collection('wallet_transactions')
          .where('user_id', isEqualTo: user.uid)
          .where('order_id', isEqualTo: tempOrderId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        await _firestore
            .collection('wallet_transactions')
            .doc(querySnapshot.docs.first.id)
            .update({'order_id': actualOrderId});
        print('Updated transaction order ID from $tempOrderId to $actualOrderId');
      }
    } catch (e) {
      print('Error updating transaction order ID: $e');
    }
  }

  // Dispose payment service
  void dispose() {
    _paymentService.dispose();
  }
}