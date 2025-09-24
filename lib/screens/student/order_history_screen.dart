import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:campus_food_app/models/order_model.dart';
import 'package:campus_food_app/services/order_service.dart';
import 'package:campus_food_app/services/auth_service.dart';
import 'package:campus_food_app/services/cancellation_request_service.dart';
import 'package:campus_food_app/services/contact_service.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final ContactService _contactService = ContactService();
  bool _isLoading = true;
  List<OrderModel> _orders = [];
  OrderStatus? _selectedStatusFilter;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _startPeriodicRefresh();
    
    // Check if we should show order tracking directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['showTracking'] == true && args['orderId'] != null) {
        _showOrderDetailsById(args['orderId']);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _loadOrders();
      }
    });
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final orders = await _orderService.getUserOrders(user.uid);
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading orders: $e')),
      );
    }
  }

  List<OrderModel> get _filteredOrders {
    if (_selectedStatusFilter == null) {
      return _orders;
    }
    return _orders
        .where((order) => order.status == _selectedStatusFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Go directly to student dashboard
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/student/home',
              (route) => false,
            );
          },
        ),
        actions: [
          PopupMenuButton<OrderStatus?>(
            onSelected: (OrderStatus? status) {
              setState(() {
                _selectedStatusFilter = status;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<OrderStatus?>>[
              const PopupMenuItem<OrderStatus?>(
                value: null,
                child: Text('All Orders'),
              ),
              ...OrderStatus.values.map((status) => PopupMenuItem<OrderStatus>(
                    value: status,
                    child: Text(
                        '${status.toString().split('.').last[0].toUpperCase()}${status.toString().split('.').last.substring(1)}'),
                  )),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredOrders.isEmpty
              ? const Center(child: Text('No orders found'))
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
      floatingActionButton: _hasActiveOrders() 
          ? FloatingActionButton.extended(
              onPressed: () {
                // Find the most recent active order and navigate to its tracking
                final activeOrders = _orders.where((order) => 
                  order.status == OrderStatus.placed || 
                  order.status == OrderStatus.accepted || 
                  order.status == OrderStatus.preparing || 
                  order.status == OrderStatus.ready
                ).toList();
                
                if (activeOrders.isNotEmpty) {
                  // Sort by order time and get the most recent
                  activeOrders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
                  _showOrderDetails(activeOrders.first);
                }
              },
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.track_changes, color: Colors.white),
              label: const Text('Track Active Order', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepPurple,
                    ),
                  ),
                  _buildStatusChip(order.status.toString().split('.').last),
                ],
              ),
              const SizedBox(height: 8),
              
              // Order time and vendor
              Text(
                'Placed: ${dateFormat.format(order.orderTime)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              FutureBuilder<Map<String, String?>>(
                future: _contactService.getVendorContactDetails(order.vendorId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final contactDetails = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vendor: ${contactDetails['name'] ?? order.vendorName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        if (contactDetails['phone'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.blue.shade600),
                              const SizedBox(width: 4),
                              Text(
                                contactDetails['phone']!,
                                style: TextStyle(color: Colors.blue.shade600),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _makePhoneCall(contactDetails['phone']!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Call',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (contactDetails['location'] != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                contactDetails['location']!,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  } else {
                    return Text(
                      'Vendor: ${order.vendorName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              
              // Order items
              const Text(
                'Items:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.quantity}x ${item.name}'),
                        Text(currencyFormat.format(item.price * item.quantity)),
                      ],
                    ),
                  )),
              const Divider(),
              
              // Total amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    currencyFormat.format(order.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              // Status-specific information
              const SizedBox(height: 12),
              _buildStatusSpecificInfo(order),
              
              // Action buttons
              const SizedBox(height: 16),
              _buildActionButtons(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'pending':
        color = Colors.blue;
        label = 'Pending';
        break;
      case 'preparing':
        color = Colors.orange;
        label = 'Preparing';
        break;
      case 'ready':
        color = Colors.purple;
        label = 'Ready for Pickup';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      case 'rejected':
        color = Colors.red.shade900;
        label = 'Rejected';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildStatusSpecificInfo(OrderModel order) {
    switch (order.status) {
      case OrderStatus.rejected:
        if (order.rejectionReason?.isNotEmpty == true) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rejected: ${order.rejectionReason}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
        
      case OrderStatus.accepted:
      case OrderStatus.preparing:
      case OrderStatus.ready:
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
                  Icon(Icons.track_changes, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Live Tracking',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (order.pickupLocation?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  '📍 ${order.pickupLocation}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
              if (order.estimatedReadyTime?.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  '⏰ ${order.estimatedReadyTime}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
              // Show cancellation request status
              if (order.cancellationRequestStatus != null) ...[
                const SizedBox(height: 8),
                _buildCancellationRequestStatus(order.cancellationRequestStatus!),
              ],
            ],
          ),
        );
        
      case OrderStatus.completed:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Order Completed',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (order.pickupTime != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Picked up: ${DateFormat('MMM d, h:mm a').format(order.pickupTime!)}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButtons(OrderModel order) {
    List<Widget> buttons = [];
    
    // View Details button for ALL orders
    buttons.add(
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _showOrderDetails(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.visibility, size: 18),
          label: const Text('View Details'),
        ),
      ),
    );
    
    // Additional action buttons based on status
    if (order.status == OrderStatus.placed) {
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _cancelOrder(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Cancel'),
          ),
        ),
      );
    } else if (order.status == OrderStatus.preparing && order.cancellationRequestStatus == null) {
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _requestCancellation(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.request_page, size: 18),
            label: const Text('Request Cancel'),
          ),
        ),
      );
    }
    
    if (order.status == OrderStatus.completed) {
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _rateOrder(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.star, size: 18),
            label: const Text('Rate'),
          ),
        ),
      );
    }
    
    return Row(children: buttons);
  }

  void _cancelOrder(OrderModel order) async {
    try {
      await _orderService.cancelOrder(order.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully')),
      );
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling order: $e')),
      );
    }
  }

  void _rateOrder(OrderModel order) {
    // This would navigate to a rating screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rating functionality would be implemented here')),
    );
  }

  void _showOrderDetailsById(String orderId) {
    // Find the order by ID
    final order = _orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => throw Exception('Order not found'),
    );
    _showOrderDetails(order);
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Order header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    _buildStatusChip(order.status.toString().split('.').last),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Order details
                _buildOrderDetailsSection(order),
                const SizedBox(height: 20),
                
                // Status-specific information
                _buildDetailedStatusInfo(order),
                const SizedBox(height: 20),
                
                // Action buttons
                _buildDetailedActionButtons(order),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailsSection(OrderModel order) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Order Time', dateFormat.format(order.orderTime)),
            _buildDetailRow('Vendor', order.vendorName),
            _buildDetailRow('Total Amount', currencyFormat.format(order.totalAmount)),
            if (order.discountedAmount < order.totalAmount)
              _buildDetailRow('Discounted Amount', currencyFormat.format(order.discountedAmount)),
            if (order.note?.isNotEmpty == true)
              _buildDetailRow('Special Instructions', order.note!),
            const SizedBox(height: 12),
            const Text(
              'Items:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity}x ${item.name}'),
                      Text(currencyFormat.format(item.price * item.quantity)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatusInfo(OrderModel order) {
    switch (order.status) {
      case OrderStatus.rejected:
        if (order.rejectionReason?.isNotEmpty == true) {
          return Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red.shade600, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Order Rejected',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reason: ${order.rejectionReason}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
        
      case OrderStatus.accepted:
      case OrderStatus.preparing:
      case OrderStatus.ready:
        return Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.track_changes, color: Colors.blue.shade600, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Live Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (order.pickupLocation?.isNotEmpty == true) ...[
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pickup Location: ${order.pickupLocation}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (order.estimatedReadyTime?.isNotEmpty == true) ...[
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimated Ready Time: ${order.estimatedReadyTime}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 16,
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
        
      case OrderStatus.completed:
        return Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Order Completed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (order.pickupTime != null) ...[
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Picked up: ${DateFormat('MMM d, yyyy h:mm a').format(order.pickupTime!)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDetailedActionButtons(OrderModel order) {
    List<Widget> buttons = [];
    
    if (order.status == OrderStatus.placed || order.status == OrderStatus.preparing) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Cancel Order'),
          ),
        ),
      );
    }
    
    if (order.status == OrderStatus.completed) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _rateOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.star, size: 18),
            label: const Text('Rate Order'),
          ),
        ),
      );
    }
    
    if (buttons.isEmpty) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Close'),
          ),
        ),
      );
    }
    
    return Row(children: buttons);
  }

  Widget _buildCancellationRequestStatus(String status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Cancellation Request Pending';
        icon = Icons.pending;
        break;
      case 'approved':
        color = Colors.green;
        label = 'Cancellation Approved';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Cancellation Rejected';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = 'Unknown Status';
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _requestCancellation(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => _CancellationRequestDialog(
        order: order,
        onRequestSubmitted: () {
          _loadOrders(); // Refresh orders to show updated status
        },
      ),
    );
  }

  bool _hasActiveOrders() {
    return _orders.any((order) => 
      order.status == OrderStatus.placed || 
      order.status == OrderStatus.accepted || 
      order.status == OrderStatus.preparing || 
      order.status == OrderStatus.ready
    );
  }
}

class _CancellationRequestDialog extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onRequestSubmitted;

  const _CancellationRequestDialog({
    required this.order,
    required this.onRequestSubmitted,
  });

  @override
  State<_CancellationRequestDialog> createState() => _CancellationRequestDialogState();
}

class _CancellationRequestDialogState extends State<_CancellationRequestDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final CancellationRequestService _cancellationService = CancellationRequestService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Order Cancellation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${widget.order.id.substring(0, 8)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vendor: ${widget.order.vendorName}',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Please provide a reason for cancellation:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter your reason for cancellation...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Note: Your cancellation request will be sent to the vendor for approval.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitCancellationRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit Request'),
        ),
      ],
    );
  }

  Future<void> _submitCancellationRequest() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for cancellation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _cancellationService.createCancellationRequest(
        orderId: widget.order.id,
        vendorId: widget.order.vendorId,
        reason: _reasonController.text.trim(),
      );

      // Update the order with cancellation request status
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({
        'cancellation_request_status': 'pending',
      });

      Navigator.pop(context);
      widget.onRequestSubmitted();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cancellation request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit cancellation request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}