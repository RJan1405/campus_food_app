import 'package:flutter/material.dart';
import 'package:campus_food_app/models/vendor_model.dart';
import 'package:campus_food_app/services/admin_service.dart';
import 'package:campus_food_app/services/vendor_service.dart';

class VendorManagementScreen extends StatefulWidget {
  const VendorManagementScreen({Key? key}) : super(key: key);

  @override
  State<VendorManagementScreen> createState() => _VendorManagementScreenState();
}

class _VendorManagementScreenState extends State<VendorManagementScreen> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final VendorService _vendorService = VendorService();
  bool _isLoading = true;
  List<VendorModel> _allVendors = [];
  List<VendorModel> _pendingVendors = [];
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVendors();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final allVendors = await _vendorService.getAllVendors();
      final pendingVendors = await _adminService.getPendingVendorApprovals();
      
      setState(() {
        _allVendors = allVendors;
        _pendingVendors = pendingVendors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading vendors: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Management'),
        backgroundColor: Colors.indigo,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Vendors'),
            Tab(text: 'Pending Approvals'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVendors,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVendorList(_allVendors, false),
                _buildVendorList(_pendingVendors, true),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add vendor screen
          // This would be implemented in a real app
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add vendor functionality would be implemented here')),
          );
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVendorList(List<VendorModel> vendors, bool isPendingList) {
    if (vendors.isEmpty) {
      return Center(
        child: Text(
          isPendingList
              ? 'No pending vendor approvals'
              : 'No vendors found',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVendors,
      child: ListView.builder(
        itemCount: vendors.length,
        itemBuilder: (context, index) {
          final vendor = vendors[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Text(
                  vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(vendor.name),
              subtitle: Text(vendor.description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPendingList) ...[
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveVendor(vendor),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectVendor(vendor),
                    ),
                  ] else ...[
                    Switch(
                      value: vendor.isOpen,
                      onChanged: (value) => _toggleVendorStatus(vendor),
                      activeColor: Colors.green,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editVendor(vendor),
                    ),
                  ],
                ],
              ),
              onTap: () => _viewVendorDetails(vendor),
            ),
          );
        },
      ),
    );
  }

  void _approveVendor(VendorModel vendor) {
    // This would call the admin service to approve the vendor
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Approved vendor: ${vendor.name}')),
    );
    _loadVendors();
  }

  void _rejectVendor(VendorModel vendor) {
    // This would call the admin service to reject the vendor
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rejected vendor: ${vendor.name}')),
    );
    _loadVendors();
  }

  void _toggleVendorStatus(VendorModel vendor) async {
    try {
      await _vendorService.toggleVendorAvailability(vendor.id, !vendor.isOpen);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vendor.isOpen
                ? 'Vendor marked as closed: ${vendor.name}'
                : 'Vendor marked as open: ${vendor.name}',
          ),
        ),
      );
      _loadVendors();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling vendor status: $e')),
      );
    }
  }

  void _editVendor(VendorModel vendor) {
    // Navigate to edit vendor screen
    // This would be implemented in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit vendor: ${vendor.name}')),
    );
  }

  void _viewVendorDetails(VendorModel vendor) {
    // Navigate to vendor details screen
    // This would be implemented in a real app
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vendor.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${vendor.id}'),
              const SizedBox(height: 8),
              Text('Description: ${vendor.description}'),
              const SizedBox(height: 8),
              Text('Location: ${vendor.location}'),
              const SizedBox(height: 8),
              Text('Owner ID: ${vendor.ownerId}'),
              const SizedBox(height: 8),
              Text('Status: ${vendor.isOpen ? "Open" : "Closed"}'),
              const SizedBox(height: 8),
              Text('Food Types: ${vendor.foodTypes.join(", ")}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}