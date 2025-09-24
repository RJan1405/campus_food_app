import 'package:cloud_firestore/cloud_firestore.dart';

class VendorModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final String ownerId; // Reference to user ID who owns this vendor
  final bool isOpen;
  final List<String> foodTypes; // e.g., ['Fast Food', 'Beverages']
  final String? imageUrl;
  final double rating;
  final int totalRatings;
  final String? phoneNumber; // Vendor contact phone number
  final String? email; // Vendor contact email
  final String? ownerName; // Name of the vendor owner
  
  VendorModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.ownerId,
    required this.isOpen,
    required this.foodTypes,
    this.imageUrl,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.phoneNumber,
    this.email,
    this.ownerName,
  });
  
  factory VendorModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return VendorModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      ownerId: data['owner_id'] ?? '',
      isOpen: data['is_open'] ?? false,
      foodTypes: data['food_types'] != null 
          ? List<String>.from(data['food_types']) 
          : [],
      imageUrl: data['image_url'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRatings: data['total_ratings'] ?? 0,
      phoneNumber: data['phone_number'],
      email: data['email'],
      ownerName: data['owner_name'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'owner_id': ownerId,
      'is_open': isOpen,
      'food_types': foodTypes,
      'image_url': imageUrl,
      'rating': rating,
      'total_ratings': totalRatings,
      'phone_number': phoneNumber,
      'email': email,
      'owner_name': ownerName,
    };
  }
}