import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_food_app/models/menu_item_model.dart';
import 'package:campus_food_app/providers/vendor_provider.dart';
import 'package:campus_food_app/providers/cart_provider.dart';
import 'package:campus_food_app/services/favorites_service.dart';
import 'package:campus_food_app/widgets/rating_widgets.dart';
import 'package:campus_food_app/screens/student/reviews_screen.dart';

class MenuScreen extends StatefulWidget {
  final String vendorId;

  const MenuScreen({Key? key, required this.vendorId}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  Map<String, bool> _favoriteStatus = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Fetch menu items when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Provider.of<VendorProvider>(context, listen: false).selectedVendor?.id != widget.vendorId) {
        Provider.of<VendorProvider>(context, listen: false).fetchVendorById(widget.vendorId);
      }
    });
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh vendor data every 60 seconds to get updated ratings
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        Provider.of<VendorProvider>(context, listen: false).fetchVendorById(widget.vendorId);
      }
    });
  }

  Future<void> _checkFavoriteStatus(String menuItemId) async {
    final isFavorite = await _favoritesService.isFavorite(menuItemId);
    setState(() {
      _favoriteStatus[menuItemId] = isFavorite;
    });
  }

  Future<void> _toggleFavorite(MenuItemModel menuItem) async {
    try {
      final isCurrentlyFavorite = _favoriteStatus[menuItem.id] ?? false;
      
      if (isCurrentlyFavorite) {
        await _favoritesService.removeFromFavorites(menuItem.id);
        setState(() {
          _favoriteStatus[menuItem.id] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await _favoritesService.addToFavorites(menuItem);
        setState(() {
          _favoriteStatus[menuItem.id] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<VendorProvider>(
          builder: (context, vendorProvider, child) {
            return Text(vendorProvider.selectedVendor?.name ?? 'Menu');
          },
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to cart screen
              Navigator.pushNamed(context, '/student/cart');
            },
          ),
        ],
      ),
      body: Consumer<VendorProvider>(
        builder: (context, vendorProvider, child) {
          if (vendorProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vendorProvider.menuItems.isEmpty) {
            return const Center(
              child: Text('No menu items available'),
            );
          }

          // Group menu items by category
          final menuItemsByCategory = <String, List<MenuItemModel>>{};
          for (var item in vendorProvider.menuItems) {
            if (!menuItemsByCategory.containsKey(item.category)) {
              menuItemsByCategory[item.category] = [];
            }
            menuItemsByCategory[item.category]!.add(item);
          }

          return ListView.builder(
            itemCount: menuItemsByCategory.length,
            itemBuilder: (context, index) {
              final category = menuItemsByCategory.keys.elementAt(index);
              final items = menuItemsByCategory[category]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, itemIndex) {
                      return _buildMenuItem(context, items[itemIndex]);
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItemModel menuItem) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu item image
            if (menuItem.imageUrl?.isNotEmpty == true)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(menuItem.imageUrl!),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Handle image loading errors gracefully
                    },
                  ),
                ),
              ),
            const SizedBox(width: 16),
            // Menu item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (menuItem.isVeg)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.circle,
                            color: Colors.green,
                            size: 8,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          menuItem.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _favoriteStatus[menuItem.id] == true 
                              ? Icons.favorite 
                              : Icons.favorite_border,
                          color: _favoriteStatus[menuItem.id] == true 
                              ? Colors.red 
                              : Colors.grey,
                        ),
                        onPressed: () {
                          _checkFavoriteStatus(menuItem.id);
                          _toggleFavorite(menuItem);
                        },
                        tooltip: _favoriteStatus[menuItem.id] == true 
                            ? 'Remove from favorites' 
                            : 'Add to favorites',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    menuItem.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${menuItem.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (menuItem.walletDiscount > 0)
                            Text(
                              menuItem.isDiscountPercentage
                                  ? '${menuItem.walletDiscount}% wallet discount'
                                  : '₹${menuItem.walletDiscount} wallet discount',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 4),
                          // Rating display
                          Row(
                            children: [
                              RatingDisplay(
                                rating: menuItem.rating,
                                totalReviews: menuItem.reviewCount,
                                size: 12,
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _navigateToMenuItemReviews(menuItem),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade50,
                                    borderRadius: BorderRadius.circular(8),
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
                                        size: 10,
                                        color: Colors.deepPurple.shade400,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Reviews',
                                        style: TextStyle(
                                          fontSize: 10,
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
                      ElevatedButton(
                        onPressed: menuItem.isAvailable
                            ? () {
                                // Add to cart
                                final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                cartProvider.addToCart(menuItem, 1);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to cart'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMenuItemReviews(MenuItemModel menuItem) async {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final vendor = vendorProvider.selectedVendor;
    
    if (vendor != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewsScreen(
            vendorId: vendor.id,
            menuItemId: menuItem.id,
            vendorName: vendor.name,
            menuItemName: menuItem.name,
          ),
        ),
      );
      
      // Refresh vendor data when returning from reviews
      try {
        vendorProvider.refreshVendorData();
      } catch (e) {
        print('Error refreshing vendor data: $e');
      }
    }
  }
}