import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';
import '../../services/github_upload_service.dart';
import '../../widgets/image_url_helper.dart';
import '../../widgets/github_config_dialog.dart';

class AddEditMenuItemDialog extends StatefulWidget {
  final MenuItemModel? menuItem;

  const AddEditMenuItemDialog({Key? key, this.menuItem}) : super(key: key);

  @override
  State<AddEditMenuItemDialog> createState() => _AddEditMenuItemDialogState();
}

class _AddEditMenuItemDialogState extends State<AddEditMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final MenuService _menuService = MenuService();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _preparationTimeController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _ingredientsController = TextEditingController();

  // Form fields
  String _selectedCategory = 'Beverages';
  bool _isVeg = true;
  bool _isAvailable = true;
  bool _isPopular = false;
  bool _isDiscountPercentage = false;
  File? _selectedImage;
  String? _existingImageUrl;
  String _imageUrl = '';
  bool _isLoading = false;

  // Categories
  final List<String> _categories = [
    'Beverages',
    'Snacks',
    'Meals',
    'Desserts',
    'Salads',
    'Sandwiches',
    'Pizza',
    'Burgers',
    'Chinese',
    'Indian',
    'Italian',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.menuItem != null) {
      _initializeFields();
    }
  }

  void _initializeFields() {
    final item = widget.menuItem!;
    _nameController.text = item.name;
    _descriptionController.text = item.description;
    _priceController.text = item.price.toString();
    _discountController.text = item.walletDiscount.toString();
    _preparationTimeController.text = item.preparationTime.toString();
    _stockQuantityController.text = item.stockQuantity == -1 ? '' : item.stockQuantity.toString();
    _ingredientsController.text = item.ingredients.join(', ');
    _selectedCategory = item.category;
    _isVeg = item.isVeg;
    _isAvailable = item.isAvailable;
    _isPopular = item.isPopular;
    _isDiscountPercentage = item.isDiscountPercentage;
    _existingImageUrl = item.imageUrl;
    _imageUrl = item.imageUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _preparationTimeController.dispose();
    _stockQuantityController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.menuItem == null ? 'Add Menu Item' : 'Edit Menu Item',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      _buildImageSection(),
                      const SizedBox(height: 20),
                      // Basic Information
                      _buildBasicInformationSection(),
                      const SizedBox(height: 20),
                      // Pricing and Discount
                      _buildPricingSection(),
                      const SizedBox(height: 20),
                      // Additional Information
                      _buildAdditionalInformationSection(),
                      const SizedBox(height: 20),
                      // Action Buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Item Image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ImageUrlHelper(),
                );
              },
              icon: const Icon(Icons.help_outline, size: 20),
              tooltip: 'How to get image URLs',
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Image URL Input
        TextFormField(
          initialValue: _imageUrl,
          decoration: InputDecoration(
            labelText: 'Image URL (Google Drive, Imgur, etc.)',
            hintText: 'https://drive.google.com/file/d/... or https://imgur.com/...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.link),
          ),
          onChanged: (value) {
            setState(() {
              _imageUrl = value.trim();
            });
          },
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final uri = Uri.tryParse(value);
              if (uri == null || !uri.hasAbsolutePath) {
                return 'Please enter a valid URL';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        
        // Image Preview
        if (_imageUrl.isNotEmpty)
          Center(
            child: Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _convertGoogleDriveUrl(_imageUrl),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Image preview error: $error');
                    return Container(
                      width: 200,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text(
                            'Image failed to load',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'URL: ${_imageUrl.length > 30 ? '${_imageUrl.substring(0, 30)}...' : _imageUrl}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Alternative: Upload from device
        Center(
          child: Column(
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Upload from Device'),
              ),
              if (!GitHubUploadService.isConfigured())
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const GitHubConfigDialog(),
                    );
                  },
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Setup GitHub Auto-Upload'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
            ],
          ),
        ),
        
        // Test Image URLs
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _imageUrl = 'https://picsum.photos/300/200';
                });
              },
              icon: const Icon(Icons.image, size: 16),
              label: const Text('Test Image'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _imageUrl = 'https://via.placeholder.com/300x200/FF6B6B/FFFFFF?text=Food+Item';
                });
              },
              icon: const Icon(Icons.photo, size: 16),
              label: const Text('Placeholder'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ],
        ),
        
        // Show selected image if uploaded from device
        if (_selectedImage != null)
          Center(
            child: Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 40,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          'Add Image',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Name
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Item Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.restaurant),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter item name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter description';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        // Category
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
        const SizedBox(height: 12),
        // Veg/Non-Veg
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Food Type:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Row(
                      children: [
                        const Icon(Icons.eco, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text('Veg'),
                      ],
                    ),
                    value: true,
                    groupValue: _isVeg,
                    onChanged: (value) {
                      setState(() {
                        _isVeg = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: Row(
                      children: [
                        const Icon(Icons.restaurant, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        const Text('Non-Veg'),
                      ],
                    ),
                    value: false,
                    groupValue: _isVeg,
                    onChanged: (value) {
                      setState(() {
                        _isVeg = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing & Discount',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Price
        TextFormField(
          controller: _priceController,
          decoration: const InputDecoration(
            labelText: 'Price (₹) *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.currency_rupee),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter price';
            }
            if (double.tryParse(value) == null || double.parse(value) <= 0) {
              return 'Please enter a valid price';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        // Discount
        TextFormField(
          controller: _discountController,
          decoration: const InputDecoration(
            labelText: 'Wallet Discount',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.discount),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null || double.parse(value) < 0) {
                return 'Please enter a valid discount';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        // Discount Type
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Discount Type:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Fixed Amount (₹)'),
                    value: false,
                    groupValue: _isDiscountPercentage,
                    onChanged: (value) {
                      setState(() {
                        _isDiscountPercentage = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Percentage (%)'),
                    value: true,
                    groupValue: _isDiscountPercentage,
                    onChanged: (value) {
                      setState(() {
                        _isDiscountPercentage = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Preparation Time
        TextFormField(
          controller: _preparationTimeController,
          decoration: const InputDecoration(
            labelText: 'Preparation Time (minutes)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.timer),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (int.tryParse(value) == null || int.parse(value) < 0) {
                return 'Please enter a valid time';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        // Stock Quantity
        TextFormField(
          controller: _stockQuantityController,
          decoration: const InputDecoration(
            labelText: 'Stock Quantity (leave empty for unlimited)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.inventory),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (int.tryParse(value) == null || int.parse(value) < 0) {
                return 'Please enter a valid quantity';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        // Ingredients
        TextFormField(
          controller: _ingredientsController,
          decoration: const InputDecoration(
            labelText: 'Ingredients (comma separated)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.list),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        // Status Options
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Available'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Popular'),
                value: _isPopular,
                onChanged: (value) {
                  setState(() {
                    _isPopular = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveMenuItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.menuItem == null ? 'Add Item' : 'Update Item'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrl = ''; // Clear URL when selecting from device
        });
        
        // Auto-upload to GitHub if configured
        if (GitHubUploadService.isConfigured()) {
          _uploadToGitHub(File(image.path));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _uploadToGitHub(File imageFile) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Show uploading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading image to GitHub...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      
      final fileName = imageFile.path.split('/').last;
      final imageUrl = await GitHubUploadService.uploadImage(imageFile, fileName);
      
      if (imageUrl != null) {
        setState(() {
          _imageUrl = imageUrl;
          _selectedImage = null; // Clear selected image since we have URL now
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded to GitHub successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload to GitHub. Using local image.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('GitHub upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GitHub upload error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting to save menu item...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      String? imageUrl;
      
      // Generate a proper ID for new items
      String itemId = widget.menuItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Use image URL if provided, otherwise try to upload from device
      if (_imageUrl.isNotEmpty) {
        imageUrl = _convertGoogleDriveUrl(_imageUrl);
        print('Using image URL: $imageUrl');
      } else if (_selectedImage != null) {
        print('Uploading image for item: $itemId');
        try {
          imageUrl = await _menuService.uploadMenuItemImage(
            _selectedImage!,
            user.uid,
            itemId,
          );
          print('Image uploaded successfully: $imageUrl');
        } catch (e) {
          print('Image upload failed: $e');
          // Continue without image if upload fails
          imageUrl = null;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed. Menu item will be saved without image.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Keep existing image URL if editing
        imageUrl = _existingImageUrl;
      }

      // Parse ingredients
      final ingredients = _ingredientsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Parse stock quantity
      final stockQuantity = _stockQuantityController.text.isEmpty
          ? -1
          : int.parse(_stockQuantityController.text);

      final menuItem = MenuItemModel(
        id: itemId,
        vendorId: user.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        walletDiscount: double.tryParse(_discountController.text) ?? 0.0,
        isDiscountPercentage: _isDiscountPercentage,
        isAvailable: _isAvailable,
        imageUrl: imageUrl,
        category: _selectedCategory,
        isVeg: _isVeg,
        createdAt: widget.menuItem?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        preparationTime: int.tryParse(_preparationTimeController.text) ?? 15,
        ingredients: ingredients,
        rating: widget.menuItem?.rating ?? 0.0,
        reviewCount: widget.menuItem?.reviewCount ?? 0,
        isPopular: _isPopular,
        stockQuantity: stockQuantity,
      );

      if (widget.menuItem == null) {
        // Add new item
        print('Adding new menu item...');
        await _menuService.addMenuItem(menuItem);
        print('Menu item added successfully!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu item added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing item
        print('Updating existing menu item...');
        await _menuService.updateMenuItem(widget.menuItem!.id, menuItem);
        print('Menu item updated successfully!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu item updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving menu item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving menu item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
