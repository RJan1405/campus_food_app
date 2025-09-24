import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../models/cancellation_request_model.dart';
import '../../services/order_service.dart';
import '../../services/cancellation_request_service.dart';
import '../../services/contact_service.dart';
import '../../utils/error_handler.dart';
import 'package:intl/intl.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with TickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final CancellationRequestService _cancellationService = CancellationRequestService();
  final ContactService _contactService = ContactService();
  late TabController _tabController;
  String _selectedStatus = 'All';

  final List<String> _statusOptions = [
    'All',
    'Placed',
    'Accepted',
    'Preparing',
    'Ready',
    'Completed',
    'Cancelled',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not make phone call'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making phone call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.toString().split('.').last}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Failed to update order status: $e');
      }
    }
  }

  Widget _buildOrderCard(OrderModel order) {
    Color statusColor = _getStatusColor(order.status);
    Color cardColor = _getCardColor(order.status);
    Color borderColor = _getBorderColor(order.status);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    order.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<Map<String, String?>>(
              future: _contactService.getUserContactDetails(order.userId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final contactDetails = snapshot.data!;
                  print('Contact details for order ${order.id}: $contactDetails');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer: ${contactDetails['name'] ?? 'Unknown'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (contactDetails['phone'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 16, color: Colors.green.shade600),
                            const SizedBox(width: 4),
                            Text(
                              contactDetails['phone']!,
                              style: TextStyle(color: Colors.green.shade600),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _makePhoneCall(contactDetails['phone']!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Call',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (contactDetails['campus_id'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${contactDetails['campus_id']}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ],
                  );
                } else {
                  print('No contact details found for order ${order.id}, userId: ${order.userId}');
                  print('Snapshot data: ${snapshot.data}');
                  print('Snapshot error: ${snapshot.error}');
                  
                  // Show a button to update user profile if contact details are missing
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer: ${order.userId.substring(0, 8)}...',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () => _updateUserProfile(order.userId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text(
                          'Update Profile',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Time: ${_formatDateTime(order.orderTime)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.name} x${item.quantity}'),
                  Text('₹${(item.discountedPrice * item.quantity).toStringAsFixed(2)}'),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '₹${order.discountedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            // Show rejection reason if rejected
            if (order.status == OrderStatus.rejected && order.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejected: ${order.rejectionReason}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Show order timeline if accepted or beyond
            if (order.status != OrderStatus.placed && order.status != OrderStatus.rejected) ...[
              const SizedBox(height: 8),
              _buildOrderTimeline(order),
            ],
            
            if (order.note != null && order.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: ${order.note}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Show cancellation request if exists
            _buildCancellationRequestWidget(order),
            
            const SizedBox(height: 12),
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    List<Widget> buttons = [];

    switch (order.status) {
      case OrderStatus.placed:
        buttons.addAll([
          ElevatedButton(
            onPressed: () => _updateOrderStatus(order.id, OrderStatus.accepted),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _showRejectOrderDialog(order),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ]);
        break;
      case OrderStatus.accepted:
        buttons.addAll([
          ElevatedButton(
            onPressed: () => _showOrderDetailsDialog(order),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Add Details'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _updateOrderStatus(order.id, OrderStatus.preparing),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Start Preparing'),
          ),
        ]);
        break;
      case OrderStatus.preparing:
        buttons.add(
          ElevatedButton(
            onPressed: () => _updateOrderStatus(order.id, OrderStatus.ready),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Mark Ready'),
          ),
        );
        break;
      case OrderStatus.ready:
        buttons.add(
          ElevatedButton(
            onPressed: () => _updateOrderStatus(order.id, OrderStatus.completed),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete'),
          ),
        );
        break;
      default:
        buttons.add(
          Text(
            'No actions available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: buttons,
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return Colors.blue;
      case OrderStatus.accepted:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildOrdersList(String statusFilter) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getVendorOrdersStream(user.uid),
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

        List<OrderModel> orders = snapshot.data ?? [];
        
        // Filter orders by status
        if (statusFilter != 'All') {
          orders = orders.where((order) {
            String orderStatusString = order.status.toString().split('.').last;
            // Capitalize first letter to match the filter options
            String capitalizedStatus = orderStatusString[0].toUpperCase() + orderStatusString.substring(1);
            return capitalizedStatus == statusFilter;
          }).toList();
        }

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  statusFilter == 'All' 
                    ? 'No orders found'
                    : 'No $statusFilter orders found',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(orders[index]);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: Colors.deepPurple,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'All', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Orders Tab
          _buildActiveOrdersTab(),
          // Today's Orders Tab
          _buildTodaysOrdersTab(),
          // All Orders Tab
          _buildAllOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getActiveVendorOrdersStream(user.uid),
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

        List<OrderModel> orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'No active orders',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'All caught up!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(orders[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildTodaysOrdersTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getVendorOrdersStream(user.uid),
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

        List<OrderModel> orders = snapshot.data ?? [];
        
        // Filter for today's orders
        final today = DateTime.now();
        orders = orders.where((order) => 
          order.orderTime.year == today.year &&
          order.orderTime.month == today.month &&
          order.orderTime.day == today.day
        ).toList();

        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.today, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No orders today',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(orders[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildAllOrdersTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Filter by Status',
              border: OutlineInputBorder(),
            ),
            items: _statusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
        ),
        Expanded(
          child: _buildOrdersList(_selectedStatus),
        ),
      ],
    );
  }

  void _showRejectOrderDialog(OrderModel order) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.id.substring(0, 8)}'),
            const SizedBox(height: 16),
            const Text(
              'Please provide a reason for rejecting this order:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Item not available, Kitchen closed, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              _updateOrderStatusWithReason(
                order.id, 
                OrderStatus.rejected, 
                reasonController.text.trim()
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatusWithReason(String orderId, OrderStatus status, String reason) async {
    try {
      await _orderService.updateOrderStatus(orderId, status, rejectionReason: reason);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${status.name} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCancellationRequest(String orderId, String requestId, String action) async {
    try {
      await _cancellationService.respondToCancellationRequest(
        requestId: requestId,
        status: action == 'approved' ? CancellationRequestStatus.approved : CancellationRequestStatus.rejected,
        vendorResponse: action == 'rejected' ? 'Cancellation request rejected by vendor' : null,
      );

      if (action == 'approved') {
        // If approved, also cancel the actual order
        await _orderService.updateOrderStatus(
          orderId,
          OrderStatus.cancelled,
          rejectionReason: 'Cancelled by customer request (approved by vendor)',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cancellation request ${action} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Failed to handle cancellation request: $e');
      }
    }
  }

  Widget _buildCancellationRequestWidget(OrderModel order) {
    return StreamBuilder<List<CancellationRequestModel>>(
      stream: _cancellationService.getVendorRequestsStream(order.vendorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        // Find cancellation request for this specific order
        final cancellationRequest = snapshot.data!.firstWhere(
          (request) => request.orderId == order.id,
          orElse: () => CancellationRequestModel(
            id: '',
            orderId: '',
            vendorId: '',
            studentId: '',
            reason: '',
            status: CancellationRequestStatus.pending,
            requestedAt: DateTime.now(),
          ),
        );

        // If no cancellation request found, return empty widget
        if (cancellationRequest.id.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cancel_presentation, color: Colors.orange.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Cancellation Request',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Reason: ${cancellationRequest.reason}',
                style: TextStyle(color: Colors.orange.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'Requested: ${_formatDateTime(cancellationRequest.requestedAt)}',
                style: TextStyle(color: Colors.orange.shade600, fontSize: 12),
              ),
              if (cancellationRequest.status == CancellationRequestStatus.pending) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleCancellationRequest(
                          order.id,
                          cancellationRequest.id,
                          'approved',
                        ),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleCancellationRequest(
                          order.id,
                          cancellationRequest.id,
                          'rejected',
                        ),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cancellationRequest.status == CancellationRequestStatus.approved
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cancellationRequest.status == CancellationRequestStatus.approved
                        ? 'APPROVED'
                        : 'REJECTED',
                    style: TextStyle(
                      color: cancellationRequest.status == CancellationRequestStatus.approved
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showOrderDetailsDialog(OrderModel order) {
    final TextEditingController locationController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.id.substring(0, 8)}'),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Pickup Location',
                hintText: 'e.g., Counter 1, Main Entrance',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Estimated Ready Time',
                hintText: 'e.g., 15 minutes, 2:30 PM',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateOrderWithDetails(
                order.id,
                locationController.text.trim(),
                timeController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Save Details'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderWithDetails(String orderId, String location, String time) async {
    try {
      await _orderService.updateOrderStatus(
        orderId,
        OrderStatus.accepted,
        pickupLocation: location.isNotEmpty ? location : null,
        estimatedReadyTime: time.isNotEmpty ? time : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order details updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getCardColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return Colors.green.shade50;
      case OrderStatus.rejected:
        return Colors.red.shade50;
      case OrderStatus.preparing:
        return Colors.orange.shade50;
      case OrderStatus.ready:
        return Colors.purple.shade50;
      case OrderStatus.completed:
        return Colors.grey.shade50;
      default:
        return Colors.white;
    }
  }

  Color _getBorderColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return Colors.green;
      case OrderStatus.rejected:
        return Colors.red;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.grey;
      default:
        return Colors.grey.shade300;
    }
  }

  Widget _buildOrderTimeline(OrderModel order) {
    List<Widget> timelineItems = [];
    
    // Order placed
    timelineItems.add(_buildTimelineItem(
      'Order Placed',
      order.orderTime,
      true,
      Icons.shopping_cart,
    ));
    
    // Order accepted
    if (order.acceptedTime != null) {
      timelineItems.add(_buildTimelineItem(
        'Order Accepted',
        order.acceptedTime!,
        true,
        Icons.check_circle,
      ));
    }
    
    // Order preparing
    if (order.preparingTime != null) {
      timelineItems.add(_buildTimelineItem(
        'Preparing',
        order.preparingTime!,
        true,
        Icons.restaurant,
      ));
    }
    
    // Order ready
    if (order.readyTime != null) {
      timelineItems.add(_buildTimelineItem(
        'Ready for Pickup',
        order.readyTime!,
        true,
        Icons.done_all,
      ));
    }
    
    // Order completed
    if (order.pickupTime != null) {
      timelineItems.add(_buildTimelineItem(
        'Completed',
        order.pickupTime!,
        true,
        Icons.check,
      ));
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.blue.shade600, size: 16),
              const SizedBox(width: 8),
              Text(
                'Order Timeline',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...timelineItems,
          if (order.pickupLocation != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Pickup: ${order.pickupLocation}',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ],
            ),
          ],
          if (order.estimatedReadyTime != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Est. Ready: ${order.estimatedReadyTime}',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, DateTime time, bool isCompleted, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isCompleted ? Colors.green.shade700 : Colors.grey.shade600,
                fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            DateFormat('HH:mm').format(time),
            style: TextStyle(
              color: isCompleted ? Colors.green.shade700 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Method to update user profile with missing contact details
  Future<void> _updateUserProfile(String userId) async {
    try {
      // Show a dialog to input user details
      final nameController = TextEditingController();
      final phoneController = TextEditingController();
      final campusIdController = TextEditingController();

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Customer Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: campusIdController,
                decoration: const InputDecoration(
                  labelText: 'Campus ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update'),
            ),
          ],
        ),
      );

      if (result == true) {
        // Update the user document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'name': nameController.text.trim(),
          'phone_number': phoneController.text.trim(),
          'campus_id': campusIdController.text.trim(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
