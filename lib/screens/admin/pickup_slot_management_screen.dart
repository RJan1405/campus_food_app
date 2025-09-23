import 'package:flutter/material.dart';
import 'package:campus_food_app/models/pickup_slot_model.dart';
import 'package:campus_food_app/models/vendor_model.dart';
import 'package:campus_food_app/services/pickup_slot_service.dart';
import 'package:campus_food_app/services/vendor_service.dart';
import 'package:intl/intl.dart';

class PickupSlotManagementScreen extends StatefulWidget {
  const PickupSlotManagementScreen({Key? key}) : super(key: key);

  @override
  State<PickupSlotManagementScreen> createState() => _PickupSlotManagementScreenState();
}

class _PickupSlotManagementScreenState extends State<PickupSlotManagementScreen> {
  final PickupSlotService _pickupSlotService = PickupSlotService();
  final VendorService _vendorService = VendorService();
  bool _isLoading = true;
  List<VendorModel> _vendors = [];
  Map<String, List<PickupSlotModel>> _vendorSlots = {};
  String? _selectedVendorId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final vendors = await _vendorService.getAllVendors();
      setState(() {
        _vendors = vendors;
        if (vendors.isNotEmpty && _selectedVendorId == null) {
          _selectedVendorId = vendors.first.id;
        }
      });
      
      if (_selectedVendorId != null) {
        await _loadVendorSlots(_selectedVendorId!);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _loadVendorSlots(String vendorId) async {
    try {
      final slots = await _pickupSlotService.getVendorPickupSlots(vendorId);
      setState(() {
        _vendorSlots[vendorId] = slots;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading slots for vendor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Slot Management'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildVendorSelector(),
                Expanded(
                  child: _selectedVendorId == null
                      ? const Center(child: Text('Select a vendor to manage pickup slots'))
                      : _buildSlotsList(_selectedVendorId!),
                ),
              ],
            ),
      floatingActionButton: _selectedVendorId == null
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddSlotDialog(_selectedVendorId!),
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildVendorSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Select Vendor',
          border: OutlineInputBorder(),
        ),
        value: _selectedVendorId,
        items: _vendors.map((vendor) {
          return DropdownMenuItem<String>(
            value: vendor.id,
            child: Text(vendor.name),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedVendorId = value;
            });
            _loadVendorSlots(value);
          }
        },
      ),
    );
  }

  Widget _buildSlotsList(String vendorId) {
    final slots = _vendorSlots[vendorId] ?? [];
    
    if (slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No pickup slots found for this vendor',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _generateDefaultSlots(vendorId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
              ),
              child: const Text('Generate Default Slots'),
            ),
          ],
        ),
      );
    }

    // Group slots by date
    final Map<String, List<PickupSlotModel>> slotsByDate = {};
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    for (var slot in slots) {
      final date = dateFormat.format(slot.startTime);
      if (!slotsByDate.containsKey(date)) {
        slotsByDate[date] = [];
      }
      slotsByDate[date]!.add(slot);
    }

    // Sort dates
    final sortedDates = slotsByDate.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () => _loadVendorSlots(vendorId),
      child: ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final dateSlots = slotsByDate[date]!;
          
          // Sort slots by start time
          dateSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(dateFormat.parse(date)),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dateSlots.length,
                itemBuilder: (context, slotIndex) {
                  final slot = dateSlots[slotIndex];
                  return _buildSlotCard(slot);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlotCard(PickupSlotModel slot) {
    final timeFormat = DateFormat('h:mm a');
    final isFull = slot.isFull;
    final isActive = slot.isActive;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          '${timeFormat.format(slot.startTime)} - ${timeFormat.format(slot.endTime)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capacity: ${slot.currentOrders.length}/${slot.capacity}'),
            Text('Status: ${isActive ? (isFull ? "Full" : "Available") : "Inactive"}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditSlotDialog(slot),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteSlot(slot),
            ),
          ],
        ),
        onTap: () => _viewSlotDetails(slot),
      ),
    );
  }

  void _generateDefaultSlots(String vendorId) async {
    try {
      await _pickupSlotService.generateDefaultSlotsForVendor(vendorId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default slots generated successfully')),
      );
      _loadVendorSlots(vendorId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating default slots: $e')),
      );
    }
  }

  void _showAddSlotDialog(String vendorId) {
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final capacityController = TextEditingController(text: '10');
    DateTime? selectedDate;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedEndTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Pickup Slot'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Date'),
                subtitle: Text(selectedDate == null 
                    ? 'Select a date' 
                    : DateFormat('EEEE, MMMM d, yyyy').format(selectedDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    selectedDate = date;
                    Navigator.of(context).pop();
                    _showAddSlotDialog(vendorId);
                  }
                },
              ),
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(selectedStartTime == null 
                    ? 'Select start time' 
                    : selectedStartTime!.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    selectedStartTime = time;
                    Navigator.of(context).pop();
                    _showAddSlotDialog(vendorId);
                  }
                },
              ),
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(selectedEndTime == null 
                    ? 'Select end time' 
                    : selectedEndTime!.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedStartTime != null 
                        ? TimeOfDay(
                            hour: (selectedStartTime!.hour + 1) % 24,
                            minute: selectedStartTime!.minute,
                          )
                        : TimeOfDay.now(),
                  );
                  if (time != null) {
                    selectedEndTime = time;
                    Navigator.of(context).pop();
                    _showAddSlotDialog(vendorId);
                  }
                },
              ),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'Maximum number of orders',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (selectedDate == null || 
                  selectedStartTime == null || 
                  selectedEndTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              
              final capacity = int.tryParse(capacityController.text) ?? 10;
              
              final startDateTime = DateTime(
                selectedDate!.year,
                selectedDate!.month,
                selectedDate!.day,
                selectedStartTime!.hour,
                selectedStartTime!.minute,
              );
              
              final endDateTime = DateTime(
                selectedDate!.year,
                selectedDate!.month,
                selectedDate!.day,
                selectedEndTime!.hour,
                selectedEndTime!.minute,
              );
              
              if (endDateTime.isBefore(startDateTime)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('End time must be after start time')),
                );
                return;
              }
              
              _createPickupSlot(
                vendorId,
                startDateTime,
                endDateTime,
                capacity,
              );
              
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _createPickupSlot(
    String vendorId,
    DateTime startTime,
    DateTime endTime,
    int capacity,
  ) async {
    try {
      final slot = PickupSlotModel(
        id: '',
        vendorId: vendorId,
        startTime: startTime,
        endTime: endTime,
        capacity: capacity,
        currentOrders: [],
        isAvailable: true,
      );
      
      await _pickupSlotService.createPickupSlot(slot);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup slot created successfully')),
      );
      _loadVendorSlots(vendorId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating pickup slot: $e')),
      );
    }
  }

  void _showEditSlotDialog(PickupSlotModel slot) {
    final capacityController = TextEditingController(text: slot.capacity.toString());
    bool isAvailable = slot.isAvailable;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pickup Slot'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Time: ${DateFormat('h:mm a').format(slot.startTime)} - ${DateFormat('h:mm a').format(slot.endTime)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'Maximum number of orders',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available'),
                value: isAvailable,
                onChanged: (value) {
                  isAvailable = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final capacity = int.tryParse(capacityController.text) ?? slot.capacity;
              
              if (capacity < slot.currentOrders.length) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Capacity cannot be less than current orders'),
                  ),
                );
                return;
              }
              
              _updatePickupSlot(
                slot.copyWith(
                  capacity: capacity,
                  isAvailable: isAvailable,
                ),
              );
              
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updatePickupSlot(PickupSlotModel slot) async {
    try {
      await _pickupSlotService.updatePickupSlot(slot);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup slot updated successfully')),
      );
      _loadVendorSlots(slot.vendorId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating pickup slot: $e')),
      );
    }
  }

  void _confirmDeleteSlot(PickupSlotModel slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pickup Slot'),
        content: Text(
          'Are you sure you want to delete this pickup slot?\n'
          '${DateFormat('EEEE, MMMM d').format(slot.startTime)}\n'
          '${DateFormat('h:mm a').format(slot.startTime)} - ${DateFormat('h:mm a').format(slot.endTime)}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePickupSlot(slot);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deletePickupSlot(PickupSlotModel slot) async {
    try {
      await _pickupSlotService.deletePickupSlot(slot.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup slot deleted successfully')),
      );
      _loadVendorSlots(slot.vendorId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting pickup slot: $e')),
      );
    }
  }

  void _viewSlotDetails(PickupSlotModel slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Slot Details - ${DateFormat('EEEE, MMMM d').format(slot.startTime)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Time: ${DateFormat('h:mm a').format(slot.startTime)} - ${DateFormat('h:mm a').format(slot.endTime)}'),
              const SizedBox(height: 8),
              Text('Capacity: ${slot.capacity}'),
              const SizedBox(height: 8),
              Text('Current Orders: ${slot.currentOrders.length}'),
              const SizedBox(height: 8),
              Text('Status: ${slot.isAvailable ? (slot.isFull ? "Full" : "Available") : "Unavailable"}'),
              if (slot.currentOrders.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Orders in this slot:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...slot.currentOrders.map((orderId) => Text('• Order ID: $orderId')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}