import 'package:flutter/foundation.dart';
import 'package:campus_food_app/models/cart_model.dart';
import 'package:campus_food_app/models/menu_item_model.dart';
import 'package:campus_food_app/services/promotion_service.dart';

class CartProvider with ChangeNotifier {
  CartModel? _cart;
  final PromotionService _promotionService = PromotionService();
  String? _appliedPromotionId;
  double _promotionDiscount = 0.0;

  CartModel? get cart => _cart;
  String? get appliedPromotionId => _appliedPromotionId;
  double get promotionDiscount => _promotionDiscount;
  
  double get totalWithPromotion => 
      _cart != null ? (_cart!.total - _promotionDiscount) : 0.0;

  void initCart(String userId) {
    _cart = CartModel(
      userId: userId,
      vendorId: '',
      items: [],
      subtotal: 0.0,
      discount: 0.0,
      total: 0.0,
    );
    _appliedPromotionId = null;
    _promotionDiscount = 0.0;
    notifyListeners();
  }

  void addItem(MenuItemModel menuItem, int quantity) {
    if (_cart == null) return;
    
    final cartItem = CartItemModel(
      menuItemId: menuItem.id,
      vendorId: menuItem.vendorId,
      name: menuItem.name,
      quantity: quantity,
      price: menuItem.price,
      discountedPrice: menuItem.discountedPrice ?? menuItem.price,
      imageUrl: menuItem.imageUrl,
    );
    
    _cart = _cart!.addItem(cartItem);
    
    // Reset promotion when adding new items
    _appliedPromotionId = null;
    _promotionDiscount = 0.0;
    
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    if (_cart == null) return;
    
    _cart = _cart!.removeItem(menuItemId);
    
    // Reset promotion when removing items
    _appliedPromotionId = null;
    _promotionDiscount = 0.0;
    
    notifyListeners();
  }

  void updateItemQuantity(String menuItemId, int quantity) {
    if (_cart == null) return;
    
    _cart = _cart!.updateItemQuantity(menuItemId, quantity);
    
    // Reset promotion when updating quantities
    _appliedPromotionId = null;
    _promotionDiscount = 0.0;
    
    notifyListeners();
  }

  void clearCart() {
    if (_cart != null) {
      _cart = CartModel(
        userId: _cart!.userId,
        vendorId: '',
        items: [],
        subtotal: 0.0,
        discount: 0.0,
        total: 0.0,
      );
      _appliedPromotionId = null;
      _promotionDiscount = 0.0;
      notifyListeners();
    }
  }

  Future<void> applyPromotion(String promotionId) async {
    if (_cart == null || _cart!.items.isEmpty) return;
    
    try {
      final discount = await _promotionService.calculatePromotionDiscount(
        promotionId, 
        _cart!.vendorId, 
        _cart!.items.map((item) => item.menuItemId).toList(), 
        _cart!.total
      );
      
      _appliedPromotionId = promotionId;
      _promotionDiscount = discount;
      notifyListeners();
    } catch (e) {
      print('Error applying promotion: $e');
    }
  }

  void removePromotion() {
    _appliedPromotionId = null;
    _promotionDiscount = 0.0;
    notifyListeners();
  }
}