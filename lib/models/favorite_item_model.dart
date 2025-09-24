import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteItemModel {
  final String id;
  final String userId;
  final String menuItemId;
  final String menuItemName;
  final String vendorId;
  final String vendorName;
  final double price;
  final double? discountedPrice;
  final String? imageUrl;
  final String? description;
  final List<String>? tags;
  final DateTime addedAt;
  final Map<String, dynamic>? metadata;

  FavoriteItemModel({
    required this.id,
    required this.userId,
    required this.menuItemId,
    required this.menuItemName,
    required this.vendorId,
    required this.vendorName,
    required this.price,
    this.discountedPrice,
    this.imageUrl,
    this.description,
    this.tags,
    required this.addedAt,
    this.metadata,
  });

  factory FavoriteItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FavoriteItemModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      menuItemId: data['menu_item_id'] ?? '',
      menuItemName: data['menu_item_name'] ?? '',
      vendorId: data['vendor_id'] ?? '',
      vendorName: data['vendor_name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      discountedPrice: data['discounted_price'] != null 
          ? (data['discounted_price'] as num).toDouble() 
          : null,
      imageUrl: data['image_url'],
      description: data['description'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      addedAt: (data['added_at'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'menu_item_id': menuItemId,
      'menu_item_name': menuItemName,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'price': price,
      'discounted_price': discountedPrice,
      'image_url': imageUrl,
      'description': description,
      'tags': tags,
      'added_at': Timestamp.fromDate(addedAt),
      'metadata': metadata,
    };
  }

  double get effectivePrice => discountedPrice ?? price;
  
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;
  
  double get discountAmount => hasDiscount ? price - discountedPrice! : 0.0;
  
  double get discountPercentage => hasDiscount ? (discountAmount / price) * 100 : 0.0;

  FavoriteItemModel copyWith({
    String? id,
    String? userId,
    String? menuItemId,
    String? menuItemName,
    String? vendorId,
    String? vendorName,
    double? price,
    double? discountedPrice,
    String? imageUrl,
    String? description,
    List<String>? tags,
    DateTime? addedAt,
    Map<String, dynamic>? metadata,
  }) {
    return FavoriteItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      addedAt: addedAt ?? this.addedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
