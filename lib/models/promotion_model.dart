import 'package:cloud_firestore/cloud_firestore.dart';

enum PromotionType {
  flatDiscount,
  percentageDiscount,
  comboDeal,
  happyHour
}

class PromotionModel {
  final String id;
  final String vendorId;
  final String title;
  final String description;
  final PromotionType type;
  final double value; // Amount or percentage
  final bool isPercentage; // True if percentage, false if fixed amount
  final DateTime startDate;
  final DateTime endDate;
  final List<String>? applicableMenuItems; // Specific items or null for all
  final double? minimumOrderValue; // Minimum order value to apply
  final int? usageLimit; // Max number of times promotion can be used
  final int usageCount; // Current usage count
  final bool isActive;
  final String? imageUrl; // For promotional banners
  
  PromotionModel({
    required this.id,
    required this.vendorId,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.isPercentage,
    required this.startDate,
    required this.endDate,
    this.applicableMenuItems,
    this.minimumOrderValue,
    this.usageLimit,
    required this.usageCount,
    required this.isActive,
    this.imageUrl,
  });
  
  factory PromotionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PromotionModel(
      id: doc.id,
      vendorId: data['vendor_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: PromotionType.values.firstWhere(
        (e) => e.toString() == 'PromotionType.${data['type'] ?? 'flatDiscount'}',
        orElse: () => PromotionType.flatDiscount,
      ),
      value: (data['value'] ?? 0.0).toDouble(),
      isPercentage: data['is_percentage'] ?? false,
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: (data['end_date'] as Timestamp).toDate(),
      applicableMenuItems: data['applicable_menu_items'] != null 
          ? List<String>.from(data['applicable_menu_items']) 
          : null,
      minimumOrderValue: data['minimum_order_value'] != null 
          ? (data['minimum_order_value'] as num).toDouble() 
          : null,
      usageLimit: data['usage_limit'],
      usageCount: data['usage_count'] ?? 0,
      isActive: data['is_active'] ?? false,
      imageUrl: data['image_url'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'vendor_id': vendorId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'value': value,
      'is_percentage': isPercentage,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'applicable_menu_items': applicableMenuItems,
      'minimum_order_value': minimumOrderValue,
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'is_active': isActive,
      'image_url': imageUrl,
    };
  }
  
  // Check if promotion is valid for current date
  bool isValidNow() {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate) && 
           (usageLimit == null || usageCount < usageLimit);
  }
  
  // Check if promotion can be applied to a specific menu item
  bool isApplicableToMenuItem(String menuItemId) {
    return applicableMenuItems == null || applicableMenuItems!.contains(menuItemId);
  }
  
  // Calculate discount amount for a given price
  double calculateDiscount(double originalPrice) {
    if (isPercentage) {
      return originalPrice * (value / 100);
    } else {
      return value;
    }
  }
  
  // Increment usage count
  PromotionModel incrementUsage() {
    return PromotionModel(
      id: id,
      vendorId: vendorId,
      title: title,
      description: description,
      type: type,
      value: value,
      isPercentage: isPercentage,
      startDate: startDate,
      endDate: endDate,
      applicableMenuItems: applicableMenuItems,
      minimumOrderValue: minimumOrderValue,
      usageLimit: usageLimit,
      usageCount: usageCount + 1,
      isActive: isActive && (usageLimit == null || usageCount + 1 < usageLimit),
      imageUrl: imageUrl,
    );
  }
}