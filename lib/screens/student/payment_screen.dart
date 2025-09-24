import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_food_app/providers/cart_provider.dart';
import 'package:campus_food_app/services/payment_service.dart';
import 'package:campus_food_app/services/order_service.dart';
import 'package:campus_food_app/services/wallet_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final OrderService _orderService = OrderService();
  String _selectedPaymentMethod = 'wallet';
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _paymentService.initListeners(_onPaymentSuccess, _onPaymentError);
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _onPaymentSuccess(dynamic response) async {
    setState(() {
      _isProcessingPayment = false;
    });
    
    try {
      // Create order after successful payment
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final orderId = await _orderService.placeOrderFromCart(
        cart: cartProvider.cart!,
        userId: user.uid,
        pickupSlotId: 'default',
        specialInstructions: '',
        paymentMethod: 'razorpay',
        paymentId: response.paymentId,
      );
      
      // Clear cart
      cartProvider.clearCart();
      
      // Navigate to order tracking and clear stack to go directly to dashboard
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/student/orders',
        (route) => route.settings.name == '/student/home',
        arguments: {'orderId': orderId, 'showTracking': true},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful but order creation failed: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _onPaymentError(dynamic response) {
    setState(() {
      _isProcessingPayment = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cart == null || cartProvider.cart!.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary
                _buildOrderSummary(cartProvider),
                const SizedBox(height: 24),
                
                // Payment Methods
                _buildPaymentMethods(),
                const SizedBox(height: 24),
                
                // Pay Button
                _buildPayButton(cartProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    final cart = cartProvider.cart!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Order items
            ...cart.allItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} x${item.quantity}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '₹${(item.discountedPrice * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            )),
            
            const Divider(),
            
            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text('₹${cart.subtotal.toStringAsFixed(2)}'),
              ],
            ),
            if (cart.discount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount:', style: TextStyle(color: Colors.green)),
                  Text('-₹${cart.discount.toStringAsFixed(2)}', 
                       style: const TextStyle(color: Colors.green)),
                ],
              ),
            ],
            if (cartProvider.promotionDiscount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Promotion:', style: TextStyle(color: Colors.green)),
                  Text('-₹${cartProvider.promotionDiscount.toStringAsFixed(2)}', 
                       style: const TextStyle(color: Colors.green)),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${cartProvider.totalWithPromotion.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Wallet Payment
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Wallet Payment'),
                ],
              ),
              subtitle: const Text('Pay using your wallet balance'),
              value: 'wallet',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            
            // Razorpay Payment
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(Icons.credit_card, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Card/UPI Payment'),
                ],
              ),
              subtitle: const Text('Pay using Razorpay (Cards, UPI, Net Banking)'),
              value: 'razorpay',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            
            // Cash on Delivery
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(Icons.money, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Cash on Delivery'),
                ],
              ),
              subtitle: const Text('Pay when you receive your order'),
              value: 'cod',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton(CartProvider cartProvider) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessingPayment ? null : () => _processPayment(cartProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isProcessingPayment
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Processing Payment...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                'Pay ₹${cartProvider.totalWithPromotion.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _processPayment(CartProvider cartProvider) async {
    // Prevent duplicate payment processing
    if (_isProcessingPayment) {
      return;
    }
    
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final totalAmount = cartProvider.totalWithPromotion;
      
      switch (_selectedPaymentMethod) {
        case 'wallet':
          await _processWalletPayment(cartProvider, totalAmount);
          break;
        case 'razorpay':
          await _processRazorpayPayment(totalAmount);
          break;
        case 'cod':
          await _processCODPayment(cartProvider);
          break;
      }
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processWalletPayment(CartProvider cartProvider, double amount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Check wallet balance first
      final walletService = WalletService();
      final currentBalance = await walletService.getWalletBalance();
      
      if (currentBalance < amount) {
        throw Exception('Insufficient wallet balance. Current: ₹${currentBalance.toStringAsFixed(2)}, Required: ₹${amount.toStringAsFixed(2)}');
      }
      
      // Process wallet payment first (deduct from wallet)
      final paymentSuccess = await walletService.processPayment(
        userId: user.uid,
        amount: amount,
        orderId: 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temporary order ID
      );
      
      if (!paymentSuccess) {
        throw Exception('Failed to process wallet payment');
      }
      
      // Create order after successful payment
      final orderId = await _orderService.placeOrderFromCart(
        cart: cartProvider.cart!,
        userId: user.uid,
        pickupSlotId: 'default',
        specialInstructions: '',
        paymentMethod: 'wallet',
        paymentId: 'wallet_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Update the transaction with the actual order ID
      await walletService.updateTransactionOrderId(
        'temp_${DateTime.now().millisecondsSinceEpoch}',
        orderId,
      );
      
      // Clear cart
      cartProvider.clearCart();
      
      setState(() {
        _isProcessingPayment = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to order tracking and clear stack to go directly to dashboard
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/student/orders',
        (route) => route.settings.name == '/student/home',
        arguments: {'orderId': orderId, 'showTracking': true},
      );
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
      throw Exception('Wallet payment failed: $e');
    }
  }

  Future<void> _processRazorpayPayment(double amount) async {
    await _paymentService.openCheckout(amount);
  }

  Future<void> _processCODPayment(CartProvider cartProvider) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Create order first
      final orderId = await _orderService.placeOrderFromCart(
        cart: cartProvider.cart!,
        userId: user.uid,
        pickupSlotId: 'default',
        specialInstructions: '',
        paymentMethod: 'cod',
        paymentId: null,
      );
      
      // Clear cart
      cartProvider.clearCart();
      
      setState(() {
        _isProcessingPayment = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully! Pay on delivery.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to order tracking and clear stack to go directly to dashboard
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/student/orders',
        (route) => route.settings.name == '/student/home',
        arguments: {'orderId': orderId, 'showTracking': true},
      );
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
      throw Exception('COD payment failed: $e');
    }
  }
}
