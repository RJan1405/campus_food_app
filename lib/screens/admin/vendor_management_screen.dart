import 'package:flutter/material.dart';
import 'package:campus_food_app/models/vendor_model.dart';
import 'package:campus_food_app/models/vendor_approval_model.dart';
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
  List<VendorApprovalModel> _pendingVendors = [];
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
      
      // Get pending vendor approvals from the stream
      final pendingVendorsStream = _adminService.getPendingVendorApprovals();
      final pendingVendors = await pendingVendorsStream.first;
      
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
                _buildPendingVendorList(_pendingVendors),
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

  Widget _buildPendingVendorList(List<VendorApprovalModel> pendingVendors) {
    if (pendingVendors.isEmpty) {
      return const Center(
        child: Text(
          'No pending vendor approvals',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVendors,
      child: ListView.builder(
        itemCount: pendingVendors.length,
        itemBuilder: (context, index) {
          final approval = pendingVendors[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.pending, color: Colors.white),
              ),
              title: Text(approval.vendorName),
              subtitle: Text(approval.vendorEmail),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approvePendingVendor(approval),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _rejectPendingVendor(approval),
                  ),
                ],
              ),
              onTap: () => _viewPendingVendorDetails(approval),
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

  void _approvePendingVendor(VendorApprovalModel approval) async {
    try {
      final currentAdmin = await _adminService.getCurrentAdmin();
      if (currentAdmin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin not found')),
        );
        return;
      }

      final success = await _adminService.approveVendor(approval.id, currentAdmin.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approved vendor: ${approval.vendorName}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve vendor')),
        );
      }
      _loadVendors();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving vendor: $e')),
      );
    }
  }

  void _rejectPendingVendor(VendorApprovalModel approval) async {
    try {
      final currentAdmin = await _adminService.getCurrentAdmin();
      if (currentAdmin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin not found')),
        );
        return;
      }

      // Show dialog to get rejection reason
      final reason = await _showRejectionDialog();
      if (reason != null && reason.isNotEmpty) {
        final success = await _adminService.rejectVendor(approval.id, currentAdmin.id, reason);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rejected vendor: ${approval.vendorName}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to reject vendor')),
          );
        }
        _loadVendors();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting vendor: $e')),
      );
    }
  }

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Vendor'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Please provide a reason for rejecting this vendor',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _viewPendingVendorDetails(VendorApprovalModel approval) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vendor Approval Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vendor Name: ${approval.vendorName}'),
            Text('Email: ${approval.vendorEmail}'),
            Text('Shop Number: ${approval.shopNumber}'),
            Text('Monthly Rent: \$${approval.monthlyRent}'),
            Text('Status: ${approval.status}'),
            Text('Submitted: ${approval.submittedAt}'),
            if (approval.document1Url.isNotEmpty)
              Text('Document 1: Available'),
            if (approval.document2Url.isNotEmpty)
              Text('Document 2: Available'),
          ],
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