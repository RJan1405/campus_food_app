import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/order_model.dart';
import '../../utils/error_handler.dart';

class VendorAnalyticsScreen extends StatefulWidget {
  const VendorAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<VendorAnalyticsScreen> createState() => _VendorAnalyticsScreenState();
}

class _VendorAnalyticsScreenState extends State<VendorAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _selectedPeriod = '7 days';
  bool _isLoading = true;
  
  // Analytics data
  int _totalOrders = 0;
  double _totalRevenue = 0.0;
  double _averageOrderValue = 0.0;
  int _completedOrders = 0;
  List<Map<String, dynamic>> _dailySales = [];
  List<Map<String, dynamic>> _topItems = [];
  Map<String, int> _orderStatusCounts = {};

  final List<String> _periodOptions = [
    '7 days',
    '30 days',
    '90 days',
    '1 year',
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Calculate date range based on selected period
      DateTime endDate = DateTime.now();
      DateTime startDate;
      
      switch (_selectedPeriod) {
        case '7 days':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case '30 days':
          startDate = endDate.subtract(const Duration(days: 30));
          break;
        case '90 days':
          startDate = endDate.subtract(const Duration(days: 90));
          break;
        case '1 year':
          startDate = endDate.subtract(const Duration(days: 365));
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }

      // Get all orders for the vendor and filter in memory to avoid complex Firestore queries
      QuerySnapshot ordersSnapshot = await _firestore
          .collection('orders')
          .where('vendor_id', isEqualTo: user.uid)
          .get();

      List<OrderModel> allOrders = ordersSnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      // Filter orders by date range in memory
      List<OrderModel> orders = allOrders.where((order) => 
        order.orderTime.isAfter(startDate) && order.orderTime.isBefore(endDate)
      ).toList();

      // Calculate analytics
      _calculateAnalytics(orders, startDate, endDate);
      
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Failed to load analytics: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateAnalytics(List<OrderModel> orders, DateTime startDate, DateTime endDate) {
    _totalOrders = orders.length;
    _totalRevenue = orders.fold(0.0, (sum, order) => sum + order.discountedAmount);
    _averageOrderValue = _totalOrders > 0 ? _totalRevenue / _totalOrders : 0.0;
    
    _completedOrders = orders.where((order) => order.status == OrderStatus.completed).length;
    
    // Calculate order status counts
    _orderStatusCounts = {};
    for (OrderModel order in orders) {
      String status = order.status.toString().split('.').last;
      _orderStatusCounts[status] = (_orderStatusCounts[status] ?? 0) + 1;
    }
    
    // Calculate daily sales
    _calculateDailySales(orders, startDate, endDate);
    
    // Calculate top items
    _calculateTopItems(orders);
  }

  void _calculateDailySales(List<OrderModel> orders, DateTime startDate, DateTime endDate) {
    Map<String, double> dailySalesMap = {};
    
    // Initialize all days with 0
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      String dateKey = '${currentDate.day}/${currentDate.month}';
      dailySalesMap[dateKey] = 0.0;
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    // Add actual sales
    for (OrderModel order in orders) {
      String dateKey = '${order.orderTime.day}/${order.orderTime.month}';
      dailySalesMap[dateKey] = (dailySalesMap[dateKey] ?? 0.0) + order.discountedAmount;
    }
    
    _dailySales = dailySalesMap.entries
        .map((entry) => {'date': entry.key, 'amount': entry.value})
        .toList();
  }

  void _calculateTopItems(List<OrderModel> orders) {
    Map<String, Map<String, dynamic>> itemCounts = {};
    
    for (OrderModel order in orders) {
      for (var item in order.items) {
        if (itemCounts.containsKey(item.name)) {
          itemCounts[item.name]!['quantity'] += item.quantity;
          itemCounts[item.name]!['revenue'] += item.discountedPrice * item.quantity;
        } else {
          itemCounts[item.name] = {
            'quantity': item.quantity,
            'revenue': item.discountedPrice * item.quantity,
          };
        }
      }
    }
    
    _topItems = itemCounts.entries
        .map((entry) => {
          'name': entry.key,
          'quantity': entry.value['quantity'],
          'revenue': entry.value['revenue'],
        })
        .toList()
      ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    
    // Take top 5 items
    _topItems = _topItems.take(5).toList();
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    if (_dailySales.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No sales data available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Sales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _dailySales.length) {
                            return Text(
                              _dailySales[value.toInt()]['date'],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dailySales.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['amount']);
                      }).toList(),
                      isCurved: true,
                      color: Colors.deepPurple,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.deepPurple.withOpacity(0.1),
                      ),
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

  Widget _buildOrderStatusChart() {
    if (_orderStatusCounts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No order status data available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    List<PieChartSectionData> sections = [];
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    int colorIndex = 0;
    _orderStatusCounts.forEach((status, count) {
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: count.toDouble(),
          title: '$count',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _orderStatusCounts.entries.map((entry) {
                      int index = _orderStatusCounts.keys.toList().indexOf(entry.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: colors[index % colors.length],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.key.toUpperCase()}: ${entry.value}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopItemsList() {
    if (_topItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No items data available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Selling Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._topItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['name'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text('${item['quantity']} sold'),
                  Text('₹${(item['revenue'] as double).toStringAsFixed(2)}'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.deepPurple,
        actions: [
          DropdownButton<String>(
            value: _selectedPeriod,
            underline: const SizedBox(),
            items: _periodOptions.map((period) {
              return DropdownMenuItem(
                value: period,
                child: Text(period),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPeriod = value!;
              });
              _loadAnalytics();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildStatCard(
                          'Total Orders',
                          _totalOrders.toString(),
                          Icons.receipt_long,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Total Revenue',
                          '₹${_totalRevenue.toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Avg Order Value',
                          '₹${_averageOrderValue.toStringAsFixed(2)}',
                          Icons.shopping_cart,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Completion Rate',
                          _totalOrders > 0 
                              ? '${((_completedOrders / _totalOrders) * 100).toStringAsFixed(1)}%'
                              : '0%',
                          Icons.check_circle,
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Sales Chart
                    _buildSalesChart(),
                    const SizedBox(height: 24),
                    
                    // Order Status Chart
                    _buildOrderStatusChart(),
                    const SizedBox(height: 24),
                    
                    // Top Items
                    _buildTopItemsList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
