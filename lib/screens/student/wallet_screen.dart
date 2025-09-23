import 'package:flutter/material.dart';
import 'package:campus_food_app/services/wallet_service.dart';
import 'package:campus_food_app/models/wallet_transaction_model.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();
  double _walletBalance = 0.0;
  bool _isLoading = true;
  List<WalletTransactionModel> _transactions = [];
  
  @override
  void initState() {
    super.initState();
    _loadWalletData();
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
        _walletBalance = balance;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading wallet data: $e')),
      );
    }
  }
  
  void _showTopUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (₹)',
            hintText: 'Enter amount to add',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                _topUpWallet(amount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
              }
            },
            child: const Text('TOP UP'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _topUpWallet(double amount) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _walletService.topUpWallet(
        amount,
        (response) {
          _loadWalletData(); // Refresh data after successful payment
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully added ₹$amount to wallet')),
          );
        },
        (error) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: $error')),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  // Using intl package for date formatting
// Using intl package for date formatting
String _formatDate(DateTime date) {
  return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
}
  
  String _getTransactionTypeText(TransactionType type) {
    switch (type) {
      case TransactionType.topup:
        return 'Top-up';
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.refund:
        return 'Refund';
      default:
        return 'Unknown';
    }
  }
  
  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.topup:
      case TransactionType.refund:
        return Colors.green;
      case TransactionType.payment:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              child: Column(
                children: [
                  // Wallet Balance Card
                  Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Current Balance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_walletBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showTopUpDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('ADD MONEY'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Transaction History
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: const [
                        Text(
                          'Transaction History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Transaction List
                  Expanded(
                    child: _transactions.isEmpty
                        ? const Center(
                            child: Text('No transactions yet'),
                          )
                        : ListView.builder(
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _transactions[index];
                              final isCredit = transaction.type == TransactionType.topup || 
                                              transaction.type == TransactionType.refund;
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getTransactionColor(transaction.type).withOpacity(0.2),
                                  child: Icon(
                                    isCredit ? Icons.add : Icons.remove,
                                    color: _getTransactionColor(transaction.type),
                                  ),
                                ),
                                title: Text(_getTransactionTypeText(transaction.type)),
                                subtitle: Text(_formatDate(transaction.timestamp)), // Using the formatted date
                                trailing: Text(
                                  '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getTransactionColor(transaction.type),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}