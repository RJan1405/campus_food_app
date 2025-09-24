import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:campus_food_app/config/razorpay_config.dart';

class PaymentService {
  final _razorpay = Razorpay();

  void initListeners(Function onPaymentSuccess, Function onPaymentError) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onPaymentError);
  }

  Future<void> openCheckout(double amount) async {
    try {
      var options = {
        ...RazorpayConfig.paymentOptions,
        'amount': (amount * 100).toInt(), // Amount in paise
      };

      if (kDebugMode) {
        print('Opening Razorpay checkout with amount: ₹$amount');
      }

      _razorpay.open(options);
    } catch (e) {
      if (kDebugMode) {
        print('Error opening Razorpay checkout: $e');
      }
      rethrow;
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}