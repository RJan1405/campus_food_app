import 'package:cloud_functions/cloud_functions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  final _functions = FirebaseFunctions.instance;
  final _razorpay = Razorpay();

  void initListeners(Function onPaymentSuccess, Function onPaymentError) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onPaymentError);
  }

  Future<void> openCheckout(double amount) async {
    try {
      // 1. Call the Cloud Function to get a secure order ID
      final HttpsCallable callable = _functions.httpsCallable('createRazorpayOrder');
      final result = await callable.call({'amount': (amount * 100).toInt()});
      final orderId = result.data['orderId'];

      var options = {
        'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your actual test key
        'amount': (amount * 100).toInt(),
        'name': 'Campus Food App',
        'description': 'Wallet Top-up',
        'order_id': orderId,
        'prefill': {
          'contact': '9876543210',
          'email': 'testuser@example.com'
        },
      };

      _razorpay.open(options);
    } catch (e) {
      print('Error calling Cloud Function: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}