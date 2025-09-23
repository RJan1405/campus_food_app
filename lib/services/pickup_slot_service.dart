import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/pickup_slot_model.dart';

class PickupSlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  final CollectionReference _pickupSlotsCollection = 
      FirebaseFirestore.instance.collection('pickup_slots');
  
  // Get all pickup slots for a vendor
  Future<List<PickupSlotModel>> getVendorPickupSlots(String vendorId) async {
    try {
      QuerySnapshot querySnapshot = await _pickupSlotsCollection
          .where('vendor_id', isEqualTo: vendorId)
          .orderBy('start_time')
          .get();
      
      return querySnapshot.docs
          .map((doc) => PickupSlotModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vendor pickup slots: $e');
      }
      throw Exception('Failed to get vendor pickup slots: $e');
    }
  }
  
  // Get available pickup slots for a vendor
  Future<List<PickupSlotModel>> getAvailablePickupSlots(String vendorId) async {
    try {
      QuerySnapshot querySnapshot = await _pickupSlotsCollection
          .where('vendor_id', isEqualTo: vendorId)
          .where('is_available', isEqualTo: true)
          .orderBy('start_time')
          .get();
      
      return querySnapshot.docs
          .map((doc) => PickupSlotModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available pickup slots: $e');
      }
      throw Exception('Failed to get available pickup slots: $e');
    }
  }
  
  // Get pickup slot by ID
  Future<PickupSlotModel> getPickupSlotById(String slotId) async {
    try {
      DocumentSnapshot doc = await _pickupSlotsCollection.doc(slotId).get();
      
      if (!doc.exists) {
        throw Exception('Pickup slot not found');
      }
      
      return PickupSlotModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pickup slot: $e');
      }
      throw Exception('Failed to get pickup slot: $e');
    }
  }
  
  // Create a new pickup slot
  Future<String> createPickupSlot(PickupSlotModel slot) async {
    try {
      // Convert PickupSlotModel to Map
      Map<String, dynamic> slotData = slot.toMap();
      
      // Add to Firestore
      DocumentReference docRef = await _pickupSlotsCollection.add(slotData);
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating pickup slot: $e');
      }
      throw Exception('Failed to create pickup slot: $e');
    }
  }
  
  // Update a pickup slot
  Future<void> updatePickupSlot(PickupSlotModel slot) async {
    try {
      await _pickupSlotsCollection.doc(slot.id).update(slot.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating pickup slot: $e');
      }
      throw Exception('Failed to update pickup slot: $e');
    }
  }
  
  // Delete a pickup slot
  Future<void> deletePickupSlot(String slotId) async {
    try {
      await _pickupSlotsCollection.doc(slotId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting pickup slot: $e');
      }
      throw Exception('Failed to delete pickup slot: $e');
    }
  }
  
  // Add an order to a pickup slot
  Future<void> addOrderToSlot(String slotId, String orderId) async {
    try {
      // Get current slot
      DocumentSnapshot doc = await _pickupSlotsCollection.doc(slotId).get();
      
      if (!doc.exists) {
        throw Exception('Pickup slot not found');
      }
      
      PickupSlotModel slot = PickupSlotModel.fromFirestore(doc);
      
      // Check if slot is full
      if (slot.isFull) {
        throw Exception('Pickup slot is already full');
      }
      
      // Update slot with new order
      PickupSlotModel updatedSlot = slot.addOrder(orderId);
      await updatePickupSlot(updatedSlot);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding order to slot: $e');
      }
      throw Exception('Failed to add order to slot: $e');
    }
  }
  
  // Remove an order from a pickup slot
  Future<void> removeOrderFromSlot(String slotId, String orderId) async {
    try {
      // Get current slot
      DocumentSnapshot doc = await _pickupSlotsCollection.doc(slotId).get();
      
      if (!doc.exists) {
        throw Exception('Pickup slot not found');
      }
      
      PickupSlotModel slot = PickupSlotModel.fromFirestore(doc);
      
      // Update slot with removed order
      PickupSlotModel updatedSlot = slot.removeOrder(orderId);
      await updatePickupSlot(updatedSlot);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing order from slot: $e');
      }
      throw Exception('Failed to remove order from slot: $e');
    }
  }
  
  // Generate default slots for a vendor
  Future<void> generateDefaultSlotsForVendor(String vendorId) async {
    try {
      // Get vendor operating hours
      DocumentSnapshot vendorDoc = await _firestore.collection('vendors').doc(vendorId).get();
      Map<String, dynamic> vendorData = vendorDoc.data() as Map<String, dynamic>;
      
      // Default slot duration in minutes
      int slotDuration = 30;
      
      // Create slots for the next 7 days
      DateTime now = DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, now.day);
      
      for (int day = 0; day < 7; day++) {
        DateTime currentDate = startDate.add(Duration(days: day));
        
        // Create slots from opening to closing time
        // Try to get opening/closing hours from vendor data, otherwise use defaults
        int openingHour = vendorData['opening_hour'] ?? 8; // Default 8 AM
        int closingHour = vendorData['closing_hour'] ?? 20; // Default 8 PM
        
        DateTime openingTime = DateTime(
          currentDate.year, 
          currentDate.month, 
          currentDate.day, 
          openingHour,
          0
        );
        
        DateTime closingTime = DateTime(
          currentDate.year, 
          currentDate.month, 
          currentDate.day, 
          closingHour,
          0
        );
        
        // Create slots
        DateTime slotStart = openingTime;
        while (slotStart.isBefore(closingTime)) {
          DateTime slotEnd = slotStart.add(Duration(minutes: slotDuration));
          
          // Check if slot already exists
          QuerySnapshot existingSlots = await _pickupSlotsCollection
              .where('vendor_id', isEqualTo: vendorId)
              .where('start_time', isEqualTo: Timestamp.fromDate(slotStart))
              .where('end_time', isEqualTo: Timestamp.fromDate(slotEnd))
              .limit(1)
              .get();
          
          // Only create if slot doesn't exist
          if (existingSlots.docs.isEmpty) {
            // Create a new slot
            PickupSlotModel slot = PickupSlotModel(
              id: '',
              vendorId: vendorId,
              startTime: slotStart,
              endTime: slotEnd,
              capacity: vendorData['default_slot_capacity'] ?? 5, // Use vendor setting or default
              currentOrders: [], // Empty list of orders
              isActive: true,
            );
            
            // Add to Firestore
            await _pickupSlotsCollection.add({
              'vendor_id': slot.vendorId,
              'start_time': Timestamp.fromDate(slot.startTime),
              'end_time': Timestamp.fromDate(slot.endTime),
              'capacity': slot.capacity,
              'current_orders': slot.currentOrders,
              'is_active': slot.isActive,
            });
          }
          
          // Move to next slot
          slotStart = slotEnd;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating default slots: $e');
      }
      throw Exception('Failed to generate default slots: $e');
    }
  }
  
  // Generate default pickup slots for a vendor
  Future<List<String>> generateDefaultPickupSlots(String vendorId) async {
    try {
      List<String> slotIds = [];
      
      // Get current date
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      
      // Create slots for today and tomorrow
      for (int day = 0; day < 2; day++) {
        DateTime date = today.add(Duration(days: day));
        
        // Create slots every 30 minutes from 8 AM to 8 PM
        for (int hour = 8; hour < 20; hour++) {
          for (int minute = 0; minute < 60; minute += 30) {
            DateTime startTime = DateTime(
              date.year, date.month, date.day, hour, minute
            );
            
            DateTime endTime = startTime.add(const Duration(minutes: 30));
            
            // Skip slots that have already passed
            if (startTime.isBefore(now)) {
              continue;
            }
            
            PickupSlotModel slot = PickupSlotModel(
              id: '',
              vendorId: vendorId,
              startTime: startTime,
              endTime: endTime,
              capacity: 5, // Default capacity
              currentOrders: [],
              isActive: true,
            );
            
            String slotId = await createPickupSlot(slot);
            slotIds.add(slotId);
          }
        }
      }
      
      return slotIds;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating default pickup slots: $e');
      }
      throw Exception('Failed to generate default pickup slots: $e');
    }
  }
  
  // Stream of pickup slots for a vendor
  Stream<List<PickupSlotModel>> vendorPickupSlotsStream(String vendorId) {
    return _pickupSlotsCollection
        .where('vendor_id', isEqualTo: vendorId)
        .orderBy('start_time')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => PickupSlotModel.fromFirestore(doc)).toList());
  }
}