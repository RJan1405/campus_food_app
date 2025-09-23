import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';
import '../../providers/user_provider.dart';
import 'add_edit_menu_item_dialog.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({Key? key}) : super(key: key);

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final MenuService _menuService = MenuService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final categories = await _menuService.getMenuCategories(user.uid);
      if (mounted) {
        setState(() {
          _categories = ['All', ...categories];
        });
      }
    }
  }

  String _convertGoogleDriveUrl(String url) {
    // Convert Google Drive sharing URL to direct image URL
    print('Original URL: $url');
    
    // Handle different Google Drive URL formats
    if (url.contains('drive.google.com/file/d/')) {
      final regex = RegExp(r'/file/d/([a-zA-Z0-9-_]+)');
      final match = regex.firstMatch(url);
      if (match != null) {
        final fileId = match.group(1);
        final convertedUrl = 'https://drive.google.com/uc?export=view&id=$fileId';
        print('Converted URL: $convertedUrl');
        return convertedUrl;
      }
    }
    
    // Handle Google Drive share URLs
    if (url.contains('drive.google.com/uc?export=view&id=')) {
      print('Already converted URL: $url');
      return url;
    }
    
    // Handle Google Drive share URLs with different format
    if (url.contains('drive.google.com/open?id=')) {
      final regex = RegExp(r'id=([a-zA-Z0-9-_]+)');
      final match = regex.firstMatch(url);
      if (match != null) {
        final fileId = match.group(1);
        final convertedUrl = 'https://drive.google.com/uc?export=view&id=$fileId';
        print('Converted from open URL: $convertedUrl');
        return convertedUrl;
      }
    }
    
    print('Using original URL: $url');
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to manage menu')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMenuItemDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search menu items...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: Colors.deepPurple.shade100,
                          checkmarkColor: Colors.deepPurple,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Menu Items List
          Expanded(
            child: _buildMenuItemsList(user.uid),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenuItemDialog(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMenuItemsList(String vendorId) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults(vendorId);
    }

    if (_selectedCategory == 'All') {
      return StreamBuilder<List<MenuItemModel>>(
        stream: _menuService.getMenuItems(vendorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final menuItems = snapshot.data ?? [];
          if (menuItems.isEmpty) {
            return _buildEmptyState();
          }

          return _buildMenuItemsGrid(menuItems);
        },
      );
    } else {
      return StreamBuilder<List<MenuItemModel>>(
        stream: _menuService.getMenuItemsByCategory(vendorId, _selectedCategory),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final menuItems = snapshot.data ?? [];
          if (menuItems.isEmpty) {
            return _buildEmptyState();
          }

          return _buildMenuItemsGrid(menuItems);
        },
      );
    }
  }

  Widget _buildSearchResults(String vendorId) {
    return FutureBuilder<List<MenuItemModel>>(
      future: _menuService.searchMenuItems(vendorId, _searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final menuItems = snapshot.data ?? [];
        if (menuItems.isEmpty) {
          return const Center(
            child: Text('No items found matching your search'),
          );
        }

        return _buildMenuItemsGrid(menuItems);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No menu items yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first menu item to get started',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddMenuItemDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Menu Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsGrid(List<MenuItemModel> menuItems) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showEditMenuItemDialog(item),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey.shade200,
                ),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          _convertGoogleDriveUrl(item.imageUrl!),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Image load error: $error');
                            return _buildPlaceholderImage();
                          },
                        ),
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name and Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: item.isAvailable ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.isAvailable ? 'A' : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    // Category and Veg/Non-Veg
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.category,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          item.isVeg ? Icons.eco : Icons.restaurant,
                          color: item.isVeg ? Colors.green : Colors.red,
                          size: 12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    // Price
                    Row(
                      children: [
                        Text(
                          item.formattedPrice,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                            fontSize: 12,
                          ),
                        ),
                        if (item.discountText.isNotEmpty) ...[
                          const SizedBox(width: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              item.discountText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => _toggleAvailability(item),
                          child: Icon(
                            item.isAvailable ? Icons.visibility_off : Icons.visibility,
                            color: item.isAvailable ? Colors.orange : Colors.green,
                            size: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showEditMenuItemDialog(item),
                          child: const Icon(Icons.edit, color: Colors.blue, size: 16),
                        ),
                        GestureDetector(
                          onTap: () => _showDeleteConfirmation(item),
                          child: const Icon(Icons.delete, color: Colors.red, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showAddMenuItemDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEditMenuItemDialog(),
    ).then((_) {
      _loadCategories(); // Refresh categories after adding
    });
  }

  void _showEditMenuItemDialog(MenuItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AddEditMenuItemDialog(menuItem: item),
    ).then((_) {
      _loadCategories(); // Refresh categories after editing
    });
  }

  void _toggleAvailability(MenuItemModel item) {
    _menuService.toggleAvailability(item.id, !item.isAvailable);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item.isAvailable 
              ? '${item.name} marked as unavailable'
              : '${item.name} marked as available',
        ),
        backgroundColor: item.isAvailable ? Colors.orange : Colors.green,
      ),
    );
  }

  void _showDeleteConfirmation(MenuItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete "${item.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMenuItem(item);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteMenuItem(MenuItemModel item) async {
    try {
      await _menuService.deleteMenuItem(item.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
