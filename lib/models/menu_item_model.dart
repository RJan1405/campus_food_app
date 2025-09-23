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
  final DateTime createdAt;
  final DateTime updatedAt;
  final int preparationTime; // Preparation time in minutes
  final List<String> ingredients; // List of ingredients
  final double rating; // Average rating
  final int reviewCount; // Number of reviews
  final bool isPopular; // Popular item flag
  final int stockQuantity; // Available quantity (-1 for unlimited)
  
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
    required this.createdAt,
    required this.updatedAt,
    required this.preparationTime,
    required this.ingredients,
    required this.rating,
    required this.reviewCount,
    required this.isPopular,
    required this.stockQuantity,
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
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preparationTime: data['preparation_time'] ?? 15,
      ingredients: List<String>.from(data['ingredients'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['review_count'] ?? 0,
      isPopular: data['is_popular'] ?? false,
      stockQuantity: data['stock_quantity'] ?? -1,
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
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'preparation_time': preparationTime,
      'ingredients': ingredients,
      'rating': rating,
      'review_count': reviewCount,
      'is_popular': isPopular,
      'stock_quantity': stockQuantity,
    };
  }

  // Helper methods
  bool get isInStock => stockQuantity == -1 || stockQuantity > 0;
  
  String get formattedPrice => '₹${price.toStringAsFixed(2)}';
  
  String get formattedDiscountedPrice => discountedPrice != null 
      ? '₹${discountedPrice!.toStringAsFixed(2)}' 
      : formattedPrice;
  
  String get discountText {
    if (walletDiscount <= 0) return '';
    if (isDiscountPercentage) {
      return '${walletDiscount.toStringAsFixed(0)}% OFF';
    } else {
      return '₹${walletDiscount.toStringAsFixed(0)} OFF';
    }
  }
  
  String get preparationTimeText {
    if (preparationTime < 60) {
      return '${preparationTime} min';
    } else {
      int hours = preparationTime ~/ 60;
      int minutes = preparationTime % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }
  
  MenuItemModel copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    double? price,
    double? discountedPrice,
    double? walletDiscount,
    bool? isDiscountPercentage,
    bool? isAvailable,
    String? imageUrl,
    String? category,
    bool? isVeg,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? preparationTime,
    List<String>? ingredients,
    double? rating,
    int? reviewCount,
    bool? isPopular,
    int? stockQuantity,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      walletDiscount: walletDiscount ?? this.walletDiscount,
      isDiscountPercentage: isDiscountPercentage ?? this.isDiscountPercentage,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isVeg: isVeg ?? this.isVeg,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preparationTime: preparationTime ?? this.preparationTime,
      ingredients: ingredients ?? this.ingredients,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isPopular: isPopular ?? this.isPopular,
      stockQuantity: stockQuantity ?? this.stockQuantity,
    );
  }
}