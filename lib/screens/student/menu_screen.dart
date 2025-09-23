import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_food_app/models/menu_item_model.dart';
import 'package:campus_food_app/providers/vendor_provider.dart';
import 'package:campus_food_app/providers/cart_provider.dart';

class MenuScreen extends StatefulWidget {
  final String vendorId;

  const MenuScreen({Key? key, required this.vendorId}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch menu items when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Provider.of<VendorProvider>(context, listen: false).selectedVendor?.id != widget.vendorId) {
        Provider.of<VendorProvider>(context, listen: false).fetchVendorById(widget.vendorId);
      }
    });
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
}