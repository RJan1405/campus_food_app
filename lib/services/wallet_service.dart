import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_food_app/models/wallet_transaction_model.dart';
import 'package:campus_food_app/services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PaymentService _paymentService = PaymentService();
  
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
        'wallet_balance': newBalance
      });
      return true;
    } catch (e) {
      print('Error updating wallet balance: $e');
      return false;
    }
  }
  
  // Add money to wallet
  Future<void> topUpWallet(double amount, Function onSuccess, Function onError) async {
    _paymentService.initListeners(
      (PaymentSuccessResponse response) async {
        // On successful payment, update wallet balance
        final currentBalance = await getWalletBalance();
        final newBalance = currentBalance + amount;
        final success = await updateWalletBalance(newBalance);
        
        if (success) {
          // Record the transaction
          await recordTransaction(
            amount: amount,
            type: TransactionType.topup,
            paymentMethod: 'Razorpay',
            transactionReference: response.paymentId,
          );
          onSuccess(response);
        } else {
          onError('Failed to update wallet balance');
        }
      },
      (PaymentFailureResponse response) {
        onError('Payment failed: ${response.message}');
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
    } catch (e) {
      print('Error recording transaction: $e');
    }
  }
  
  // Get wallet transaction history
  Future<List<WalletTransactionModel>> getTransactionHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      
      final snapshot = await _firestore
          .collection('wallet_transactions')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();
      
      return snapshot.docs
          .map((doc) => WalletTransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }
  
  // Dispose payment service
  void dispose() {
    _paymentService.dispose();
  }
}