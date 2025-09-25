import 'package:flutter/material.dart';
import '../../services/vendor_approval_service.dart';
import '../../services/auth_service.dart';
import '../../models/vendor_approval_model.dart';
import 'vendor_approval_screen.dart';

class VendorStatusScreen extends StatefulWidget {
  const VendorStatusScreen({Key? key}) : super(key: key);

  @override
  _VendorStatusScreenState createState() => _VendorStatusScreenState();
}

class _VendorStatusScreenState extends State<VendorStatusScreen> {
  final _vendorApprovalService = VendorApprovalService();
  final _authService = AuthService();
  VendorApprovalModel? _approval;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApprovalStatus();
  }

  Future<void> _loadApprovalStatus() async {
    try {
      final approval = await _vendorApprovalService.getCurrentVendorApproval();
      setState(() {
        _approval = approval;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _vendorApprovalService.deleteVendorAccount();
        if (success) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account. Please try again.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Vendor Status'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              await _authService.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await _authService.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Vendor Status'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            await _authService.signOut();
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusTitle(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(),
                                ),
                              ),
                              Text(
                                _getStatusMessage(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_approval != null) ...[
                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 16),
                      _buildApprovalDetails(),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Action Buttons
            if (_approval == null) ...[
              // No approval request submitted
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VendorApprovalScreen(),
                      ),
                    ).then((_) => _loadApprovalStatus());
                  },
                  icon: Icon(Icons.upload_file),
                  label: Text('Submit Approval Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else if (_approval!.isPending) ...[
              // Pending approval
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.hourglass_empty, color: Colors.orange, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Your request is under review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Our admin team will review your documents and get back to you soon.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_approval!.isRejected) ...[
              // Rejected
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Request Rejected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      if (_approval!.rejectionReason != null) ...[
                        Text(
                          'Reason: ${_approval!.rejectionReason}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[600]),
                        ),
                        SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _deleteAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Delete Account'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_approval!.isApproved) ...[
              // Approved
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Congratulations!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your vendor account has been approved. You can now access all vendor features.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.green[600]),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/vendor-dashboard',
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Go to Vendor Dashboard'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Approval Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        _buildDetailRow('Shop Number', _approval!.shopNumber),
        _buildDetailRow('Monthly Rent', '₹${_approval!.monthlyRent.toStringAsFixed(0)}'),
        _buildDetailRow('Submitted On', _formatDate(_approval!.submittedAt)),
        if (_approval!.reviewedAt != null)
          _buildDetailRow('Reviewed On', _formatDate(_approval!.reviewedAt!)),
        if (_approval!.document1Name.isNotEmpty)
          _buildDetailRow('Document 1', _approval!.document1Name),
        if (_approval!.document2Name.isNotEmpty)
          _buildDetailRow('Document 2', _approval!.document2Name),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  IconData _getStatusIcon() {
    if (_approval == null) return Icons.pending_actions;
    switch (_approval!.status) {
      case VendorApprovalStatus.pending:
        return Icons.hourglass_empty;
      case VendorApprovalStatus.approved:
        return Icons.check_circle;
      case VendorApprovalStatus.rejected:
        return Icons.cancel;
    }
  }

  Color _getStatusColor() {
    if (_approval == null) return Colors.blue;
    switch (_approval!.status) {
      case VendorApprovalStatus.pending:
        return Colors.orange;
      case VendorApprovalStatus.approved:
        return Colors.green;
      case VendorApprovalStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusTitle() {
    if (_approval == null) return 'No Request Submitted';
    switch (_approval!.status) {
      case VendorApprovalStatus.pending:
        return 'Pending Approval';
      case VendorApprovalStatus.approved:
        return 'Approved';
      case VendorApprovalStatus.rejected:
        return 'Rejected';
    }
  }

  String _getStatusMessage() {
    if (_approval == null) return 'Submit your approval request to become a vendor';
    switch (_approval!.status) {
      case VendorApprovalStatus.pending:
        return 'Your request is under review by our admin team';
      case VendorApprovalStatus.approved:
        return 'Your vendor account is active and ready to use';
      case VendorApprovalStatus.rejected:
        return 'Your request was not approved. Please contact support for more information';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
