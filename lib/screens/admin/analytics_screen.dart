import 'package:flutter/material.dart';
import 'package:campus_food_app/services/admin_service.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic> _dashboardStats = {};
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stats = await _adminService.getDashboardStatistics();
      setState(() {
        _dashboardStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: Colors.indigo,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Orders'),
            Tab(text: 'Transactions'),
            Tab(text: 'Users'),
            Tab(text: 'Vendors'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersAnalytics(),
                _buildTransactionsAnalytics(),
                _buildUsersAnalytics(),
                _buildVendorsAnalytics(),
              ],
            ),
    );
  }

  Widget _buildOrdersAnalytics() {
    final orderStats = _dashboardStats['orders'] ?? {};
    
    if (orderStats.isEmpty) {
      return const Center(child: Text('No order statistics available'));
    }
    
    final totalOrders = orderStats['total_orders'] ?? 0;
    final completedOrders = orderStats['completed_orders'] ?? 0;
    final cancelledOrders = orderStats['cancelled_orders'] ?? 0;
    final pendingOrders = totalOrders - completedOrders - cancelledOrders;
    final totalSales = orderStats['total_sales'] ?? 0.0;
    final completionRate = orderStats['completion_rate'] ?? 0.0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Statistics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatCard(
            'Total Sales',
            '\$${totalSales.toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.green,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  '$totalOrders',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Completion Rate',
                  '${(completionRate * 100).toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Order Status Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: completedOrders.toDouble(),
                    title: 'Completed\n$completedOrders',
                    color: Colors.green,
                    radius: 100,
                  ),
                  PieChartSectionData(
                    value: pendingOrders.toDouble(),
                    title: 'Pending\n$pendingOrders',
                    color: Colors.orange,
                    radius: 100,
                  ),
                  PieChartSectionData(
                    value: cancelledOrders.toDouble(),
                    title: 'Cancelled\n$cancelledOrders',
                    color: Colors.red,
                    radius: 100,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // This would generate and download a report in a real app
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order report would be generated here')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download Order Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsAnalytics() {
    final transactionStats = _dashboardStats['transactions'] ?? {};
    
    if (transactionStats.isEmpty) {
      return const Center(child: Text('No transaction statistics available'));
    }
    
    final totalTransactions = transactionStats['total_transactions'] ?? 0.0;
    final totalTopups = transactionStats['total_topups'] ?? 0.0;
    final totalPayments = transactionStats['total_payments'] ?? 0.0;
    final totalRefunds = transactionStats['total_refunds'] ?? 0.0;
    final transactionCount = transactionStats['transaction_count'] ?? 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Statistics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatCard(
            'Total Transaction Volume',
            '\$${totalTransactions.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
            Colors.indigo,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Transaction Count',
                  '$transactionCount',
                  Icons.receipt_long,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Avg. Transaction',
                  '\$${transactionCount > 0 ? (totalTransactions / transactionCount).toStringAsFixed(2) : "0.00"}',
                  Icons.trending_up,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Transaction Type Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: totalTopups > totalPayments && totalTopups > totalRefunds
                    ? totalTopups * 1.2
                    : totalPayments > totalRefunds
                        ? totalPayments * 1.2
                        : totalRefunds * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String type;
                      switch (groupIndex) {
                        case 0:
                          type = 'Top-ups';
                          break;
                        case 1:
                          type = 'Payments';
                          break;
                        case 2:
                          type = 'Refunds';
                          break;
                        default:
                          type = '';
                      }
                      return BarTooltipItem(
                        '$type\n\$${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Top-ups';
                            break;
                          case 1:
                            text = 'Payments';
                            break;
                          case 2:
                            text = 'Refunds';
                            break;
                          default:
                            text = '';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: totalTopups,
                        color: Colors.blue,
                        width: 25,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: totalPayments,
                        color: Colors.green,
                        width: 25,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: totalRefunds,
                        color: Colors.red,
                        width: 25,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // This would generate and download a report in a real app
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction report would be generated here')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download Transaction Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersAnalytics() {
    final userStats = _dashboardStats['users'] ?? {};
    
    if (userStats.isEmpty) {
      return const Center(child: Text('No user statistics available'));
    }
    
    final totalUsers = userStats['total_users'] ?? 0;
    final students = userStats['students'] ?? 0;
    final staff = userStats['staff'] ?? 0;
    final vendors = userStats['vendors'] ?? 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Statistics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatCard(
            'Total Users',
            '$totalUsers',
            Icons.people,
            Colors.blue,
          ),
          const SizedBox(height: 24),
          const Text(
            'User Role Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: students.toDouble(),
                    title: 'Students\n$students',
                    color: Colors.blue,
                    radius: 100,
                  ),
                  PieChartSectionData(
                    value: staff.toDouble(),
                    title: 'Staff\n$staff',
                    color: Colors.green,
                    radius: 100,
                  ),
                  PieChartSectionData(
                    value: vendors.toDouble(),
                    title: 'Vendors\n$vendors',
                    color: Colors.orange,
                    radius: 100,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // This would generate and download a report in a real app
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User report would be generated here')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download User Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorsAnalytics() {
    final vendorStats = _dashboardStats['vendors'] ?? {};
    
    if (vendorStats.isEmpty) {
      return const Center(child: Text('No vendor statistics available'));
    }
    
    final totalVendors = vendorStats['total_vendors'] ?? 0;
    final activeVendors = vendorStats['active_vendors'] ?? 0;
    final inactiveVendors = vendorStats['inactive_vendors'] ?? 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vendor Statistics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatCard(
            'Total Vendors',
            '$totalVendors',
            Icons.store,
            Colors.indigo,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Vendors',
                  '$activeVendors',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Inactive Vendors',
                  '$inactiveVendors',
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Vendor Status Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: activeVendors.toDouble(),
                    title: 'Active\n$activeVendors',
                    color: Colors.green,
                    radius: 100,
                  ),
                  PieChartSectionData(
                    value: inactiveVendors.toDouble(),
                    title: 'Inactive\n$inactiveVendors',
                    color: Colors.red,
                    radius: 100,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // This would generate and download a report in a real app
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vendor report would be generated here')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download Vendor Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}