import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/vendor_approval_service.dart';
import '../../services/auth_service.dart';

class VendorApprovalScreen extends StatefulWidget {
  const VendorApprovalScreen({Key? key}) : super(key: key);

  @override
  _VendorApprovalScreenState createState() => _VendorApprovalScreenState();
}

class _VendorApprovalScreenState extends State<VendorApprovalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNumberController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _vendorApprovalService = VendorApprovalService();
  final _authService = AuthService();

  final _document1UrlController = TextEditingController();
  final _document2UrlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _shopNumberController.dispose();
    _monthlyRentController.dispose();
    _document1UrlController.dispose();
    _document2UrlController.dispose();
    super.dispose();
  }

  Future<void> _submitApproval() async {
    if (_formKey.currentState!.validate()) {
      if (_document1UrlController.text.trim().isEmpty || _document2UrlController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please provide both document links.';
        });
        return;
      }

      // Validate Google Drive URLs
      if (!_document1UrlController.text.contains('drive.google.com') || 
          !_document2UrlController.text.contains('drive.google.com')) {
        setState(() {
          _errorMessage = 'Please provide valid Google Drive links.';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not logged in.');
        }

        final userData = await _authService.getUserData(user.uid);
        if (userData == null) {
          throw Exception('User data not found.');
        }

        final success = await _vendorApprovalService.submitVendorApproval(
          shopNumber: _shopNumberController.text.trim(),
          monthlyRent: double.parse(_monthlyRentController.text.trim()),
          document1Url: _document1UrlController.text.trim(),
          document2Url: _document2UrlController.text.trim(),
          document1Name: 'Identity Proof Document',
          document2Name: 'Business Proof Document',
        );

        if (!success) {
          throw Exception('Failed to submit approval request');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Approval request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/vendor/status');
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vendor Approval'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vendor Approval Required',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'To become a vendor, you need to submit the following information and documents for approval by our admin team.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // Shop Details
              Text(
                'Shop Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              
              TextFormField(
                controller: _shopNumberController,
                decoration: InputDecoration(
                  labelText: 'Shop Number',
                  hintText: 'e.g., Shop A-101',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter shop number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _monthlyRentController,
                decoration: InputDecoration(
                  labelText: 'Monthly Rent (₹)',
                  hintText: 'e.g., 15000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter monthly rent';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              
              // Document Upload
              Text(
                'Required Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              
              // Document 1
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document 1: Proof of Identity',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upload Aadhar Card, PAN Card, or Driving License to Google Drive and paste the shareable link',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _document1UrlController,
                        decoration: InputDecoration(
                          labelText: 'Google Drive Link',
                          hintText: 'https://drive.google.com/file/d/...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.help_outline),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('How to get Google Drive link'),
                                  content: Text(
                                    '1. Upload your document to Google Drive\n'
                                    '2. Right-click on the file\n'
                                    '3. Select "Get link"\n'
                                    '4. Change access to "Anyone with the link"\n'
                                    '5. Copy the link and paste it here',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide the document link';
                          }
                          if (!value.contains('drive.google.com')) {
                            return 'Please provide a valid Google Drive link';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Document 2
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document 2: Business Proof',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upload Rent Agreement, Business License, or Shop Registration to Google Drive and paste the shareable link',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _document2UrlController,
                        decoration: InputDecoration(
                          labelText: 'Google Drive Link',
                          hintText: 'https://drive.google.com/file/d/...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.help_outline),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('How to get Google Drive link'),
                                  content: Text(
                                    '1. Upload your document to Google Drive\n'
                                    '2. Right-click on the file\n'
                                    '3. Select "Get link"\n'
                                    '4. Change access to "Anyone with the link"\n'
                                    '5. Copy the link and paste it here',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide the document link';
                          }
                          if (!value.contains('drive.google.com')) {
                            return 'Please provide a valid Google Drive link';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApproval,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting...'),
                          ],
                        )
                      : Text(
                          'Submit for Approval',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              SizedBox(height: 20),
              
              // Information Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Important Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Your approval request will be reviewed by our admin team\n'
                        '• You will receive a notification once your request is processed\n'
                        '• Until approved, you cannot access vendor features\n'
                        '• Make sure all documents are clear and readable',
                        style: TextStyle(color: Colors.blue[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
