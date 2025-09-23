import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final double price;
  final double? discountedPrice; // Price after wallet discount
  final double walletDiscount; // Amount or percentage of discount
  final bool isDiscountPercentage; // true if discount is percentage, false if fixed amount
  final bool isAvailable;
  final String? imageUrl;
  final String category; // e.g., 'Beverages', 'Snacks', 'Meals'
  final bool isVeg; // Vegetarian indicator
  
  MenuItemModel({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.price,
    this.discountedPrice,
    required this.walletDiscount,
    required this.isDiscountPercentage,
    required this.isAvailable,
    this.imageUrl,
    required this.category,
    required this.isVeg,
  });
  
  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    double price = (data['price'] ?? 0.0).toDouble();
    double walletDiscount = (data['wallet_discount'] ?? 0.0).toDouble();
    bool isDiscountPercentage = data['is_discount_percentage'] ?? false;
    
    // Calculate discounted price
    double? discountedPrice;
    if (walletDiscount > 0) {
      if (isDiscountPercentage) {
        discountedPrice = price - (price * walletDiscount / 100);
      } else {
        discountedPrice = price - walletDiscount;
      }
    }
    
    return MenuItemModel(
      id: doc.id,
      vendorId: data['vendor_id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: price,
      discountedPrice: discountedPrice,
      walletDiscount: walletDiscount,
      isDiscountPercentage: isDiscountPercentage,
      isAvailable: data['is_available'] ?? true,
      imageUrl: data['image_url'],
      category: data['category'] ?? 'Other',
      isVeg: data['is_veg'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'vendor_id': vendorId,
      'name': name,
      'description': description,
      'price': price,
      'wallet_discount': walletDiscount,
      'is_discount_percentage': isDiscountPercentage,
      'is_available': isAvailable,
      'image_url': imageUrl,
      'category': category,
      'is_veg': isVeg,
    };
  }
}