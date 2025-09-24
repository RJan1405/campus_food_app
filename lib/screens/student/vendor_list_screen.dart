import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_food_app/models/vendor_model.dart';
import 'package:campus_food_app/providers/vendor_provider.dart';
import 'package:campus_food_app/screens/student/menu_screen.dart';
import 'package:campus_food_app/widgets/rating_widgets.dart';
import 'package:campus_food_app/screens/student/reviews_screen.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({Key? key}) : super(key: key);

  @override
  _VendorListScreenState createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Fetch vendors when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VendorProvider>(context, listen: false).fetchAllVendors();
    });
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh vendors every 60 seconds to get updated ratings
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        Provider.of<VendorProvider>(context, listen: false).fetchAllVendors();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Food Vendors'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Consumer<VendorProvider>(
        builder: (context, vendorProvider, child) {
          if (vendorProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vendorProvider.vendors.isEmpty) {
            return const Center(
              child: Text('No vendors available at the moment'),
            );
          }

          return ListView.builder(
            itemCount: vendorProvider.vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendorProvider.vendors[index];
              return _buildVendorCard(context, vendor);
            },
          );
        },
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, VendorModel vendor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Select vendor and navigate to menu screen
          Provider.of<VendorProvider>(context, listen: false)
              .fetchVendorById(vendor.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuScreen(vendorId: vendor.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Vendor image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: vendor.imageUrl?.isNotEmpty == true
                        ? NetworkImage(vendor.imageUrl!)
                        : const AssetImage('assets/images/placeholder_food.jpg') as ImageProvider,
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Handle image loading errors gracefully
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Vendor details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendor.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: vendor.isOpen ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vendor.isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            color: vendor.isOpen ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Rating display
                    Row(
                      children: [
                        RatingDisplay(
                          rating: vendor.rating ?? 0.0,
                          totalReviews: vendor.totalRatings ?? 0,
                          size: 14,
                        ),
                        const Spacer(),
                        // Reviews button
                        GestureDetector(
                          onTap: () => _navigateToReviews(vendor),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.deepPurple.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.deepPurple.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Reviews',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.deepPurple.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow icon
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReviews(VendorModel vendor) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsScreen(
          vendorId: vendor.id,
          vendorName: vendor.name,
        ),
      ),
    );
    
    // Refresh vendor data when returning from reviews
    try {
      Provider.of<VendorProvider>(context, listen: false).refreshVendorData();
    } catch (e) {
      print('Error refreshing vendor data: $e');
    }
  }
}