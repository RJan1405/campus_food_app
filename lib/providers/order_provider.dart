import 'package:flutter/foundation.dart';
import 'package:campus_food_app/models/order_model.dart';
import 'package:campus_food_app/services/order_service.dart';

class OrderProvider with ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  final OrderService _orderService = OrderService();

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchUserOrders(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _orderService.getUserOrders(userId);
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> placeOrder({
    required String userId,
    required String vendorId,
    required String vendorName,
    required List<OrderItemModel> items,
    required double totalAmount,
    required double discountedAmount,
    required double walletSavings,
    String? note,
    DateTime? pickupTime,
    String? promotionId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final order = await _orderService.placeOrder(
        userId: userId,
        vendorId: vendorId,
        vendorName: vendorName,
        items: items,
        totalAmount: totalAmount,
        discountedAmount: discountedAmount,
        walletSavings: walletSavings,
        note: note,
        pickupTime: pickupTime,
        promotionId: promotionId,
      );
      
      if (order != null) {
        _orders.insert(0, order);
      }
      
      return order;
    } catch (e) {
      print('Error placing order: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      final success = await _orderService.cancelOrder(orderId);
      
      if (success) {
        // Update the local order status
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1) {
          final updatedOrder = await _orderService.getOrderById(orderId);
          _orders[index] = updatedOrder;
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }
}