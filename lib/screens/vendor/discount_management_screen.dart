import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/promotion_model.dart';
import '../../services/promotion_service.dart';
import '../../utils/error_handler.dart';

class DiscountManagementScreen extends StatefulWidget {
  const DiscountManagementScreen({Key? key}) : super(key: key);

  @override
  State<DiscountManagementScreen> createState() => _DiscountManagementScreenState();
}

class _DiscountManagementScreenState extends State<DiscountManagementScreen> {
  final PromotionService _promotionService = PromotionService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deletePromotion(String promotionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: const Text('Are you sure you want to delete this promotion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _promotionService.deletePromotion(promotionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promotion deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, 'Failed to delete promotion: $e');
        }
      }
    }
  }

  Future<void> _togglePromotionStatus(String promotionId, bool currentStatus) async {
    try {
      await _promotionService.togglePromotionStatus(promotionId, !currentStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promotion ${!currentStatus ? 'activated' : 'deactivated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Failed to update promotion status: $e');
      }
    }
  }

  Widget _buildPromotionCard(PromotionModel promotion) {
    final isExpired = DateTime.now().isAfter(promotion.endDate);
    final isActive = promotion.isActive && !isExpired;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    promotion.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : isExpired ? 'EXPIRED' : 'INACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              promotion.description,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getPromotionIcon(promotion.type),
                  size: 20,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                Text(
                  _getPromotionTypeText(promotion),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  '${promotion.usageCount}/${promotion.usageLimit ?? '∞'} uses',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(promotion.startDate)} - ${_formatDate(promotion.endDate)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            if (promotion.minimumOrderValue != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Min order: ₹${promotion.minimumOrderValue!.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _togglePromotionStatus(promotion.id, promotion.isActive),
                  icon: Icon(
                    promotion.isActive ? Icons.pause : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(promotion.isActive ? 'Deactivate' : 'Activate'),
                ),
                TextButton.icon(
                  onPressed: () => _showEditPromotionDialog(promotion),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _deletePromotion(promotion.id),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPromotionIcon(PromotionType type) {
    switch (type) {
      case PromotionType.flatDiscount:
        return Icons.money_off;
      case PromotionType.percentageDiscount:
        return Icons.percent;
      case PromotionType.comboDeal:
        return Icons.local_offer;
      case PromotionType.happyHour:
        return Icons.access_time;
    }
  }

  String _getPromotionTypeText(PromotionModel promotion) {
    switch (promotion.type) {
      case PromotionType.flatDiscount:
        return 'Flat ₹${promotion.value.toStringAsFixed(2)} off';
      case PromotionType.percentageDiscount:
        return '${promotion.value.toStringAsFixed(0)}% off';
      case PromotionType.comboDeal:
        return 'Combo Deal';
      case PromotionType.happyHour:
        return 'Happy Hour';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditPromotionDialog(PromotionModel promotion) {
    showDialog(
      context: context,
      builder: (context) => AddEditPromotionDialog(
        promotion: promotion,
        onSaved: () {
          setState(() {});
        },
      ),
    );
  }

  void _showAddPromotionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditPromotionDialog(
        onSaved: () {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discount Management'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPromotionDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search promotions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
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
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PromotionModel>>(
              stream: _promotionService.vendorPromotionsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                List<PromotionModel> promotions = snapshot.data ?? [];
                
                // Filter promotions based on search query
                if (_searchQuery.isNotEmpty) {
                  promotions = promotions.where((promotion) =>
                    promotion.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    promotion.description.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                if (promotions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_offer, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty 
                            ? 'No promotions found matching "$_searchQuery"'
                            : 'No promotions created yet',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddPromotionDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Promotion'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    itemCount: promotions.length,
                    itemBuilder: (context, index) {
                      return _buildPromotionCard(promotions[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPromotionDialog,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class AddEditPromotionDialog extends StatefulWidget {
  final PromotionModel? promotion;
  final VoidCallback onSaved;

  const AddEditPromotionDialog({
    Key? key,
    this.promotion,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<AddEditPromotionDialog> createState() => _AddEditPromotionDialogState();
}

class _AddEditPromotionDialogState extends State<AddEditPromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  final PromotionService _promotionService = PromotionService();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _minimumOrderController = TextEditingController();
  final _usageLimitController = TextEditingController();

  PromotionType _selectedType = PromotionType.percentageDiscount;
  bool _isPercentage = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.promotion != null) {
      _initializeFields();
    }
  }

  void _initializeFields() {
    final promotion = widget.promotion!;
    _titleController.text = promotion.title;
    _descriptionController.text = promotion.description;
    _valueController.text = promotion.value.toString();
    _minimumOrderController.text = promotion.minimumOrderValue?.toString() ?? '';
    _usageLimitController.text = promotion.usageLimit?.toString() ?? '';
    _selectedType = promotion.type;
    _isPercentage = promotion.isPercentage;
    _startDate = promotion.startDate;
    _endDate = promotion.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _minimumOrderController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _savePromotion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final promotion = PromotionModel(
        id: widget.promotion?.id ?? '',
        vendorId: user.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        value: double.parse(_valueController.text),
        isPercentage: _isPercentage,
        startDate: _startDate,
        endDate: _endDate,
        applicableMenuItems: null, // Can be extended later
        minimumOrderValue: _minimumOrderController.text.isNotEmpty 
            ? double.parse(_minimumOrderController.text) 
            : null,
        usageLimit: _usageLimitController.text.isNotEmpty 
            ? int.parse(_usageLimitController.text) 
            : null,
        usageCount: widget.promotion?.usageCount ?? 0,
        isActive: widget.promotion?.isActive ?? true,
      );

      if (widget.promotion != null) {
        await _promotionService.updatePromotion(promotion);
      } else {
        await _promotionService.createPromotion(promotion);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promotion ${widget.promotion != null ? 'updated' : 'created'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Failed to save promotion: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.promotion != null ? 'Edit Promotion' : 'Create Promotion'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PromotionType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Promotion Type',
                  border: OutlineInputBorder(),
                ),
                items: PromotionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getPromotionTypeName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _valueController,
                      decoration: InputDecoration(
                        labelText: _isPercentage ? 'Percentage (%)' : 'Amount (₹)',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a value';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _isPercentage,
                    onChanged: (value) {
                      setState(() {
                        _isPercentage = value;
                      });
                    },
                  ),
                  Text(_isPercentage ? '%' : '₹'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minimumOrderController,
                      decoration: const InputDecoration(
                        labelText: 'Min Order (₹)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _usageLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Usage Limit',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text('Start: ${_formatDate(_startDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text('End: ${_formatDate(_endDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _savePromotion,
          child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.promotion != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  String _getPromotionTypeName(PromotionType type) {
    switch (type) {
      case PromotionType.flatDiscount:
        return 'Flat Discount';
      case PromotionType.percentageDiscount:
        return 'Percentage Discount';
      case PromotionType.comboDeal:
        return 'Combo Deal';
      case PromotionType.happyHour:
        return 'Happy Hour';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
