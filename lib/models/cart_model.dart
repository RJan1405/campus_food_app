import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String menuItemId;
  final String vendorId;
  final String name;
  final int quantity;
  final double price;
  final double discountedPrice;
  final String? imageUrl;
  
  CartItemModel({
    required this.menuItemId,
    required this.vendorId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.discountedPrice,
    this.imageUrl,
  });
  
  factory CartItemModel.fromMap(Map<String, dynamic> data) {
    return CartItemModel(
      menuItemId: data['menu_item_id'] ?? '',
      vendorId: data['vendor_id'] ?? '',
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      discountedPrice: (data['discounted_price'] ?? 0.0).toDouble(),
      imageUrl: data['image_url'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'menu_item_id': menuItemId,
      'vendor_id': vendorId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'discounted_price': discountedPrice,
      'image_url': imageUrl,
    };
  }
  
  CartItemModel copyWith({
    String? menuItemId,
    String? vendorId,
    String? name,
    int? quantity,
    double? price,
    double? discountedPrice,
    String? imageUrl,
  }) {
    return CartItemModel(
      menuItemId: menuItemId ?? this.menuItemId,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class CartModel {
  final String userId;
  final String vendorId; // Single vendor per cart
  final List<CartItemModel> items;
  final double subtotal;
  final double discount;
  final double total;
  
  CartModel({
    required this.userId,
    required this.vendorId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
  });
  
  factory CartModel.empty(String userId) {
    return CartModel(
      userId: userId,
      vendorId: '',
      items: [],
      subtotal: 0.0,
      discount: 0.0,
      total: 0.0,
    );
  }
  
  factory CartModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    List<CartItemModel> items = [];
    
    if (data['items'] != null) {
      items = (data['items'] as List).map((item) => 
        CartItemModel.fromMap(item as Map<String, dynamic>)
      ).toList();
    }
    
    return CartModel(
      userId: data['user_id'] ?? '',
      vendorId: data['vendor_id'] ?? '',
      items: items,
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      discount: (data['discount'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'vendor_id': vendorId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
    };
  }
  
  // Helper methods
  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  
  // Calculate totals based on current items
  CartModel recalculate() {
    double newSubtotal = 0.0;
    double newDiscount = 0.0;
    
    for (var item in items) {
      newSubtotal += item.price * item.quantity;
      newDiscount += (item.price - item.discountedPrice) * item.quantity;
    }
    
    return CartModel(
      userId: userId,
      vendorId: vendorId,
      items: items,
      subtotal: newSubtotal,
      discount: newDiscount,
      total: newSubtotal - newDiscount,
    );
  }
  
  // Add item to cart
  CartModel addItem(CartItemModel newItem) {
    // Check if adding from a different vendor
    if (vendorId.isNotEmpty && vendorId != newItem.vendorId) {
      // Replace cart with new vendor
      return CartModel(
        userId: userId,
        vendorId: newItem.vendorId,
        items: [newItem],
        subtotal: newItem.price * newItem.quantity,
        discount: (newItem.price - newItem.discountedPrice) * newItem.quantity,
        total: newItem.discountedPrice * newItem.quantity,
      );
    }
    
    // Check if item already exists
    int existingIndex = items.indexWhere((item) => item.menuItemId == newItem.menuItemId);
    List<CartItemModel> updatedItems = List.from(items);
    
    if (existingIndex >= 0) {
      // Update existing item quantity
      CartItemModel existingItem = items[existingIndex];
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + newItem.quantity
      );
    } else {
      // Add new item
      updatedItems.add(newItem);
    }
    
    return CartModel(
      userId: userId,
      vendorId: newItem.vendorId,
      items: updatedItems,
      subtotal: 0.0,
      discount: 0.0,
      total: 0.0,
    ).recalculate();
  }
  
  // Remove item from cart
  CartModel removeItem(String menuItemId) {
    List<CartItemModel> updatedItems = items.where((item) => item.menuItemId != menuItemId).toList();
    
    return CartModel(
      userId: userId,
      vendorId: updatedItems.isEmpty ? '' : vendorId,
      items: updatedItems,
      subtotal: 0.0,
      discount: 0.0,
      total: 0.0,
    ).recalculate();
  }
  
  // Update item quantity
  CartModel updateItemQuantity(String menuItemId, int quantity) {
    List<CartItemModel> updatedItems = List.from(items);
    int itemIndex = items.indexWhere((item) => item.menuItemId == menuItemId);
    
    if (itemIndex >= 0) {
      if (quantity <= 0) {
        updatedItems.removeAt(itemIndex);
      } else {
        updatedItems[itemIndex] = items[itemIndex].copyWith(quantity: quantity);
      }
    }
    
    return CartModel(
      userId: userId,
      vendorId: updatedItems.isEmpty ? '' : vendorId,
      items: updatedItems,
      subtotal: 0.0,
      discount: 0.0,
      total: 0.0,
    ).recalculate();
  }
  
  // Clear cart
  CartModel clear() {
    return CartModel.empty(userId);
  }
}