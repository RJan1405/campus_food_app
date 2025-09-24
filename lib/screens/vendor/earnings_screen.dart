import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_food_app/services/vendor_wallet_service.dart';
import 'package:campus_food_app/models/vendor_wallet_transaction_model.dart';

class VendorEarningsScreen extends StatefulWidget {
  const VendorEarningsScreen({Key? key}) : super(key: key);

  @override
  State<VendorEarningsScreen> createState() => _VendorEarningsScreenState();
}

class _VendorEarningsScreenState extends State<VendorEarningsScreen> {
  final VendorWalletService _vendorWalletService = VendorWalletService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic> _earningsSummary = {};
  List<VendorWalletTransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      setState(() {
        _isLoading = true;
      });

      // Load earnings summary
      final summary = await _vendorWalletService.getVendorEarningsSummary(user.uid);
      
      // Load transaction history
      final transactions = await _vendorWalletService.getVendorTransactionHistory(user.uid);

      setState(() {
        _earningsSummary = summary;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading earnings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEarningsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarningsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earnings Summary Cards
                    _buildEarningsSummary(),
                    const SizedBox(height: 24),
                    
                    // Transaction History
                    const Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_transactions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      _buildTransactionList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEarningsSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earnings Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildSummaryCard(
              'Current Balance',
              '₹${_earningsSummary['current_balance']?.toStringAsFixed(2) ?? '0.00'}',
              Colors.green,
              Icons.account_balance_wallet,
            ),
            _buildSummaryCard(
              'Total Earnings',
              '₹${_earningsSummary['total_earnings']?.toStringAsFixed(2) ?? '0.00'}',
              Colors.blue,
              Icons.trending_up,
            ),
            _buildSummaryCard(
              'Total Refunds',
              '₹${_earningsSummary['total_refunds']?.toStringAsFixed(2) ?? '0.00'}',
              Colors.orange,
              Icons.trending_down,
            ),
            _buildSummaryCard(
              'Total Orders',
              '${_earningsSummary['total_orders'] ?? 0}',
              Colors.purple,
              Icons.receipt_long,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(VendorWalletTransactionModel transaction) {
    Color cardColor;
    IconData icon;
    String typeText;
    
    switch (transaction.type) {
      case VendorTransactionType.orderPayment:
        cardColor = Colors.green;
        icon = Icons.add_circle;
        typeText = 'Order Payment';
        break;
      case VendorTransactionType.refund:
        cardColor = Colors.red;
        icon = Icons.remove_circle;
        typeText = 'Refund';
        break;
      case VendorTransactionType.withdrawal:
        cardColor = Colors.blue;
        icon = Icons.account_balance;
        typeText = 'Withdrawal';
        break;
      case VendorTransactionType.adjustment:
        cardColor = Colors.orange;
        icon = Icons.edit;
        typeText = 'Adjustment';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cardColor.withOpacity(0.1),
          child: Icon(icon, color: cardColor),
        ),
        title: Text(
          typeText,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null)
              Text(transaction.description!),
            Text(
              _formatDateTime(transaction.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Text(
          '${transaction.amount >= 0 ? '+' : ''}₹${transaction.amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: transaction.amount >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
