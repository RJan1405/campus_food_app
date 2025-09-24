import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_food_app/services/transaction_service.dart';
import 'package:campus_food_app/models/transaction_model.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TransactionService _transactionService = TransactionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TransactionModel> _transactions = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _userId;
  TransactionType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      _loadTransactionData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTransactionData() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _summary = await _transactionService.getUserTransactionSummary(_userId!);
      _transactionService.getUserTransactionHistory(_userId!).listen((transactions) {
        if (mounted) {
          setState(() {
            _transactions = _filterTransactions(transactions);
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading transaction data: $e');
      if (mounted) {
        // If it's an index error, show empty state instead of error
        if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
          setState(() {
            _transactions = [];
            _summary = {};
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load transactions: $e')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    if (_selectedFilter == null) return transactions;
    return transactions.where((t) => t.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          PopupMenuButton<TransactionType?>(
            onSelected: (TransactionType? type) {
              setState(() {
                _selectedFilter = type;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<TransactionType?>>[
              const PopupMenuItem<TransactionType?>(
                value: null,
                child: Text('All Transactions'),
              ),
              ...TransactionType.values.map((type) => PopupMenuItem<TransactionType>(
                    value: type,
                    child: Text(_getTransactionTypeDisplayName(type)),
                  )),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactionData,
            tooltip: 'Refresh Transactions',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactionData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Card
                    if (_summary.isNotEmpty) _buildSummaryCard(),
                    const SizedBox(height: 16),

                    // Transactions List
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _transactions.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No transactions yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Your transaction history will appear here',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _transactions[index];
                              return _buildTransactionCard(transaction);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.deepPurple.shade700,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Transactions',
                    '${_summary['total_transactions'] ?? 0}',
                    Icons.receipt_long,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Spent',
                    '₹${(_summary['total_spent'] ?? 0.0).toStringAsFixed(2)}',
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Received',
                    '₹${(_summary['total_received'] ?? 0.0).toStringAsFixed(2)}',
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Net Balance',
                    '₹${((_summary['total_received'] ?? 0.0) - (_summary['total_spent'] ?? 0.0)).toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isPositive 
              ? Colors.green.shade100 
              : Colors.red.shade100,
          child: Icon(
            _getTransactionIcon(transaction.type),
            color: transaction.isPositive 
                ? Colors.green.shade700 
                : Colors.red.shade700,
          ),
        ),
        title: Text(
          transaction.typeDisplayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.description),
            if (transaction.vendorName != null)
              Text('Vendor: ${transaction.vendorName}'),
            if (transaction.orderId != null)
              Text('Order: ${transaction.orderId!.substring(0, 8)}...'),
            Text(
              DateFormat('MMM d, yyyy - hh:mm a').format(transaction.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              transaction.formattedAmount,
              style: TextStyle(
                color: transaction.isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (transaction.paymentMethod != null)
              Text(
                transaction.paymentMethod!.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.walletTopUp:
        return Icons.add_circle;
      case TransactionType.walletPayment:
        return Icons.payment;
      case TransactionType.walletRefund:
        return Icons.refresh;
      case TransactionType.orderPayment:
        return Icons.shopping_cart;
      case TransactionType.orderRefund:
        return Icons.undo;
      case TransactionType.orderCancellation:
        return Icons.cancel;
    }
  }

  String _getTransactionTypeDisplayName(TransactionType type) {
    switch (type) {
      case TransactionType.walletTopUp:
        return 'Wallet Top-up';
      case TransactionType.walletPayment:
        return 'Wallet Payment';
      case TransactionType.walletRefund:
        return 'Wallet Refund';
      case TransactionType.orderPayment:
        return 'Order Payment';
      case TransactionType.orderRefund:
        return 'Order Refund';
      case TransactionType.orderCancellation:
        return 'Order Cancellation';
    }
  }
}
