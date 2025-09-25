import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/admin_service.dart';
import '../../models/vendor_approval_model.dart';

class VendorApprovalManagementScreen extends StatefulWidget {
  const VendorApprovalManagementScreen({Key? key}) : super(key: key);

  @override
  _VendorApprovalManagementScreenState createState() => _VendorApprovalManagementScreenState();
}

class _VendorApprovalManagementScreenState extends State<VendorApprovalManagementScreen> {
  final _adminService = AdminService();
  final _rejectionReasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _approveVendor(VendorApprovalModel approval) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve Vendor'),
        content: Text('Are you sure you want to approve ${approval.vendorName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('Starting vendor approval process...');
        final admin = await _adminService.getCurrentAdmin();
        print('Current admin: $admin');
        
        if (admin != null) {
          print('Admin found, calling approveVendor with approvalId: ${approval.id}, adminId: ${admin.id}');
          final success = await _adminService.approveVendor(approval.id, admin.id);
          print('Approval result: $success');
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vendor approved successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to approve vendor'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          print('Admin is null!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Admin not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error in approval process: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rejectVendor(VendorApprovalModel approval) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Vendor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject ${approval.vendorName}?'),
            SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              decoration: InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Please provide a reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _rejectionReasonController.clear();
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_rejectionReasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(_rejectionReasonController.text.trim());
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('Starting vendor rejection process...');
        final admin = await _adminService.getCurrentAdmin();
        print('Current admin: $admin');
        
        if (admin != null) {
          print('Admin found, calling rejectVendor with approvalId: ${approval.id}, adminId: ${admin.id}, reason: $reason');
          final success = await _adminService.rejectVendor(approval.id, admin.id, reason);
          print('Rejection result: $success');
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vendor rejected successfully'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to reject vendor'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          print('Admin is null!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Admin not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error in rejection process: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
        _rejectionReasonController.clear();
      }
    }
  }

  Future<void> _viewDocument(String url, String name) async {
    try {
      // For Google Drive links, we'll show them in a dialog with copy functionality
      if (url.contains('drive.google.com')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('$name - Google Drive Link'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Google Drive Link:'),
                SizedBox(height: 8),
                SelectableText(
                  url,
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (await canLaunch(url)) {
                      await launch(url);
                      Navigator.of(context).pop();
                    }
                  },
                  icon: Icon(Icons.open_in_new),
                  label: Text('Open in Browser'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          ),
        );
      } else {
        // For other URLs, try to open directly
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open document: $name')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vendor Approvals'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<VendorApprovalModel>>(
        stream: _adminService.getAllVendorApprovals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final approvals = snapshot.data ?? [];

          if (approvals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No vendor approvals found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: approvals.length,
            itemBuilder: (context, index) {
              final approval = approvals[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getStatusColor(approval.status),
                            child: Icon(
                              _getStatusIcon(approval.status),
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  approval.vendorName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  approval.vendorEmail,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(approval.statusDisplayName),
                            backgroundColor: _getStatusColor(approval.status).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _getStatusColor(approval.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Details
                      _buildDetailRow('Shop Number', approval.shopNumber),
                      _buildDetailRow('Monthly Rent', '₹${approval.monthlyRent.toStringAsFixed(0)}'),
                      _buildDetailRow('Submitted', _formatDate(approval.submittedAt)),
                      if (approval.reviewedAt != null)
                        _buildDetailRow('Reviewed', _formatDate(approval.reviewedAt!)),
                      if (approval.rejectionReason != null)
                        _buildDetailRow('Rejection Reason', approval.rejectionReason!),

                      SizedBox(height: 16),

                      // Documents
                      Text(
                        'Documents',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDocumentButton(
                              'Document 1',
                              approval.document1Name,
                              approval.document1Url,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildDocumentButton(
                              'Document 2',
                              approval.document2Name,
                              approval.document2Url,
                            ),
                          ),
                        ],
                      ),

                      // Actions
                      if (approval.isPending) ...[
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : () => _rejectVendor(approval),
                                icon: Icon(Icons.cancel),
                                label: Text('Reject'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : () => _approveVendor(approval),
                                icon: Icon(Icons.check),
                                label: Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentButton(String title, String name, String url) {
    return OutlinedButton.icon(
      onPressed: () => _viewDocument(url, name),
      icon: Icon(Icons.visibility, size: 16),
      label: Text(
        name.isNotEmpty ? name : title,
        style: TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  IconData _getStatusIcon(VendorApprovalStatus status) {
    switch (status) {
      case VendorApprovalStatus.pending:
        return Icons.hourglass_empty;
      case VendorApprovalStatus.approved:
        return Icons.check_circle;
      case VendorApprovalStatus.rejected:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(VendorApprovalStatus status) {
    switch (status) {
      case VendorApprovalStatus.pending:
        return Colors.orange;
      case VendorApprovalStatus.approved:
        return Colors.green;
      case VendorApprovalStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
