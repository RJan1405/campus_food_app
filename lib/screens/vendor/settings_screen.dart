import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../utils/error_handler.dart';

class VendorSettingsScreen extends StatefulWidget {
  const VendorSettingsScreen({Key? key}) : super(key: key);

  @override
  State<VendorSettingsScreen> createState() => _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends State<VendorSettingsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cuisineController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _vendorData;
  
  // Business hours
  Map<String, Map<String, TimeOfDay?>> _businessHours = {
    'Monday': {'open': null, 'close': null},
    'Tuesday': {'open': null, 'close': null},
    'Wednesday': {'open': null, 'close': null},
    'Thursday': {'open': null, 'close': null},
    'Friday': {'open': null, 'close': null},
    'Saturday': {'open': null, 'close': null},
    'Sunday': {'open': null, 'close': null},
  };
  
  bool _isOpen24Hours = false;
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cuisineController.dispose();
    super.dispose();
  }

  Future<void> _loadVendorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot doc = await _firestore.collection('vendors').doc(user.uid).get();
      
      if (doc.exists) {
        _vendorData = doc.data() as Map<String, dynamic>;
        _initializeFields();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Failed to load vendor data: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeFields() {
    if (_vendorData != null) {
      _businessNameController.text = _vendorData!['business_name'] ?? '';
      _descriptionController.text = _vendorData!['description'] ?? '';
      _phoneController.text = _vendorData!['phone'] ?? '';
      _addressController.text = _vendorData!['address'] ?? '';
      _cuisineController.text = _vendorData!['cuisine'] ?? '';
      
      // Load business hours
      if (_vendorData!['business_hours'] != null) {
        Map<String, dynamic> hours = _vendorData!['business_hours'];
        _businessHours = {};
        for (String day in hours.keys) {
          Map<String, dynamic> dayHours = hours[day];
          _businessHours[day] = {
            'open': dayHours['open'] != null 
                ? TimeOfDay.fromDateTime(DateTime.parse(dayHours['open']))
                : null,
            'close': dayHours['close'] != null 
                ? TimeOfDay.fromDateTime(DateTime.parse(dayHours['close']))
                : null,
          };
        }
      }
      
      _isOpen24Hours = _vendorData!['is_open_24_hours'] ?? false;
      _isClosed = _vendorData!['is_closed'] ?? false;
    }
  }

  Future<void> _selectTime(BuildContext context, String day, String type) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _businessHours[day]![type] ?? const TimeOfDay(hour: 9, minute: 0),
    );
    
    if (picked != null) {
      setState(() {
        _businessHours[day]![type] = picked;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Prepare business hours data
      Map<String, Map<String, String?>> businessHoursData = {};
      for (String day in _businessHours.keys) {
        businessHoursData[day] = {
          'open': _businessHours[day]!['open'] != null 
              ? '${_businessHours[day]!['open']!.hour.toString().padLeft(2, '0')}:${_businessHours[day]!['open']!.minute.toString().padLeft(2, '0')}'
              : null,
          'close': _businessHours[day]!['close'] != null 
              ? '${_businessHours[day]!['close']!.hour.toString().padLeft(2, '0')}:${_businessHours[day]!['close']!.minute.toString().padLeft(2, '0')}'
              : null,
        };
      }

      Map<String, dynamic> vendorData = {
        'business_name': _businessNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'cuisine': _cuisineController.text.trim(),
        'business_hours': businessHoursData,
        'is_open_24_hours': _isOpen24Hours,
        'is_closed': _isClosed,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('vendors').doc(user.uid).set(
        vendorData,
        SetOptions(merge: true),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Failed to save settings: $e');
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildBusinessHoursSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Hours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Quick options
            Column(
              children: [
                CheckboxListTile(
                  title: const Text('Open 24 Hours'),
                  value: _isOpen24Hours,
                  onChanged: (value) {
                    setState(() {
                      _isOpen24Hours = value ?? false;
                      if (_isOpen24Hours) {
                        _isClosed = false;
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Currently Closed'),
                  value: _isClosed,
                  onChanged: (value) {
                    setState(() {
                      _isClosed = value ?? false;
                      if (_isClosed) {
                        _isOpen24Hours = false;
                      }
                    });
                  },
                ),
              ],
            ),
            
            if (!_isOpen24Hours && !_isClosed) ...[
              const Divider(),
              const SizedBox(height: 16),
              ..._businessHours.keys.map((day) => _buildDayHours(day)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayHours(String day) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context, day, 'open'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _businessHours[day]!['open'] != null
                          ? _businessHours[day]!['open']!.format(context)
                          : 'Open',
                      style: TextStyle(
                        color: _businessHours[day]!['open'] != null 
                            ? Colors.black 
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('to'),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context, day, 'close'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _businessHours[day]!['close'] != null
                          ? _businessHours[day]!['close']!.format(context)
                          : 'Close',
                      style: TextStyle(
                        color: _businessHours[day]!['close'] != null 
                            ? Colors.black 
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
              trailing: const Icon(Icons.lock),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implement change password
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Change password feature coming soon'),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Business Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter business name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cuisineController,
                        decoration: const InputDecoration(
                          labelText: 'Cuisine Type',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter cuisine type';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Business Hours
              _buildBusinessHoursSection(),
              const SizedBox(height: 16),
              
              // Account Settings
              _buildAccountSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
