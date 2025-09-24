import 'package:flutter/material.dart';
import 'package:campus_food_app/services/wallet_service.dart';
import 'package:campus_food_app/models/wallet_transaction_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();
  double _currentBalance = 0.0;
  bool _isLoading = false;
  bool _isTopUpLoading = false;
  List<WalletTransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh wallet data when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWalletData();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _walletService.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final balance = await _walletService.getWalletBalance();
      final transactions = await _walletService.getTransactionHistory();
      
      setState(() {
        _currentBalance = balance;
        _transactions = transactions;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load wallet data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showTopUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amount to add to your wallet:'),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _amountController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isTopUpLoading ? null : _processTopUp,
            child: _isTopUpLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Top Up'),
          ),
        ],
      ),
    );
  }

  Future<void> _processTopUp() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showErrorSnackBar('Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    if (amount < 10) {
      _showErrorSnackBar('Minimum top-up amount is ₹10');
      return;
    }

    setState(() {
      _isTopUpLoading = true;
    });

    try {
      await _walletService.topUpWallet(
        amount,
        (response) {
          // Success callback
          setState(() {
            _isTopUpLoading = false;
          });
          _amountController.clear();
          Navigator.pop(context);
          _showSuccessSnackBar('Wallet topped up successfully!');
          _loadWalletData(); // Refresh wallet data
        },
        (error) {
          // Error callback
          setState(() {
            _isTopUpLoading = false;
          });
          _showErrorSnackBar(error.toString());
        },
      );
    } catch (e) {
      setState(() {
        _isTopUpLoading = false;
      });
      _showErrorSnackBar('Failed to process top-up: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWalletData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet Balance Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Current Balance',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_currentBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showTopUpDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Top Up Wallet'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._transactions.map((transaction) => _buildTransactionCard(transaction)),
                ],
              ),
            ),
    );
  }

  Widget _buildTransactionCard(WalletTransactionModel transaction) {
    final isCredit = transaction.amount > 0;
    final amountColor = isCredit ? Colors.green : Colors.red;
    final amountPrefix = isCredit ? '+' : '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: amountColor.withOpacity(0.1),
          child: Icon(
            isCredit ? Icons.add : Icons.remove,
            color: amountColor,
          ),
        ),
        title: Text(_getTransactionTypeText(transaction.type)),
        subtitle: Text(
          _formatDateTime(transaction.timestamp),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '$amountPrefix₹${transaction.amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: amountColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _getTransactionTypeText(TransactionType type) {
    switch (type) {
      case TransactionType.topup:
        return 'Wallet Top-up';
      case TransactionType.purchase:
        return 'Order Payment';
      case TransactionType.refund:
        return 'Refund';
      default:
        return 'Transaction';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}