import 'package:cloud_firestore/cloud_firestore.dart';

class VendorConnectionFixer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fix vendor connection by creating vendor documents for existing vendor users
  Future<void> fixVendorConnections() async {
    try {
      print('Starting vendor connection fix...');
      
      // Get all users with vendor role
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'vendor')
          .get();
      
      print('Found ${usersSnapshot.docs.length} vendor users');
      
      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        // Check if vendor document already exists
        DocumentSnapshot vendorDoc = await _firestore
            .collection('vendors')
            .doc(userId)
            .get();
        
        if (!vendorDoc.exists) {
          // Create vendor document
          String vendorName = userData['name'] ?? 
              (userData['email'] ?? 'Unknown Vendor').split('@')[0];
          
          await _firestore.collection('vendors').doc(userId).set({
            'name': vendorName,
            'description': 'Welcome to $vendorName! We serve delicious food.',
            'location': 'Campus Food Court',
            'owner_id': userId,
            'is_open': true,
            'food_types': ['Fast Food', 'Beverages'],
            'image_url': null,
            'rating': 0.0,
            'total_ratings': 0,
            'phone_number': userData['phone_number'] ?? '',
            'campus_id': userData['campus_id'] ?? '',
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
          
          print('Created vendor document for: $vendorName (ID: $userId)');
        } else {
          print('Vendor document already exists for: ${userData['name']} (ID: $userId)');
        }
      }
      
      print('Vendor connection fix completed successfully!');
    } catch (e) {
      print('Error fixing vendor connections: $e');
      throw Exception('Failed to fix vendor connections: $e');
    }
  }

  // Create a test vendor with menu items
  Future<void> createTestVendorWithMenu() async {
    try {
      print('Creating test vendor with menu items...');
      
      // Create a test vendor document
      String testVendorId = 'test_vendor_${DateTime.now().millisecondsSinceEpoch}';
      
      await _firestore.collection('vendors').doc(testVendorId).set({
        'name': 'Campus Pizza Corner',
        'description': 'Delicious pizzas and Italian food for students',
        'location': 'Campus Food Court - Block A',
        'owner_id': testVendorId,
        'is_open': true,
        'food_types': ['Pizza', 'Italian', 'Fast Food'],
        'image_url': null,
        'rating': 4.5,
        'total_ratings': 25,
        'phone_number': '9876543210',
        'campus_id': 'VENDOR_PIZZA_001',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // Create menu items for the test vendor
      List<Map<String, dynamic>> menuItems = [
        {
          'name': 'Margherita Pizza',
          'description': 'Classic pizza with tomato sauce, mozzarella, and basil',
          'price': 199.0,
          'category': 'Pizza',
          'vendor_id': testVendorId,
          'is_available': true,
          'image_url': null,
          'preparation_time': 15,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Pepperoni Pizza',
          'description': 'Pizza topped with pepperoni and mozzarella cheese',
          'price': 249.0,
          'category': 'Pizza',
          'vendor_id': testVendorId,
          'is_available': true,
          'image_url': null,
          'preparation_time': 18,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Chicken Burger',
          'description': 'Juicy chicken patty with fresh vegetables',
          'price': 149.0,
          'category': 'Fast Food',
          'vendor_id': testVendorId,
          'is_available': true,
          'image_url': null,
          'preparation_time': 10,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        {
          'name': 'French Fries',
          'description': 'Crispy golden french fries',
          'price': 79.0,
          'category': 'Fast Food',
          'vendor_id': testVendorId,
          'is_available': true,
          'image_url': null,
          'preparation_time': 8,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Coca Cola',
          'description': 'Refreshing cold drink',
          'price': 45.0,
          'category': 'Beverages',
          'vendor_id': testVendorId,
          'is_available': true,
          'image_url': null,
          'preparation_time': 2,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
      ];
      
      for (Map<String, dynamic> menuItem in menuItems) {
        await _firestore.collection('menu_items').add(menuItem);
      }
      
      print('Test vendor created successfully with ${menuItems.length} menu items');
      print('Vendor ID: $testVendorId');
    } catch (e) {
      print('Error creating test vendor: $e');
      throw Exception('Failed to create test vendor: $e');
    }
  }

  // Fix vendor ID mismatch by updating menu items to use correct Firebase UID
  Future<void> fixVendorIdMismatch() async {
    try {
      print('Starting vendor ID mismatch fix...');
      
      // Get all vendor users
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'vendor')
          .get();
      
      print('Found ${usersSnapshot.docs.length} vendor users');
      
      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        String firebaseUid = userDoc.id;
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String vendorName = userData['name'] ?? 'Unknown Vendor';
        
        print('Processing vendor: $vendorName (Firebase UID: $firebaseUid)');
        
        // Find all menu items that might belong to this vendor
        // We'll look for menu items with vendor names or similar patterns
        QuerySnapshot menuItemsSnapshot = await _firestore
            .collection('menu_items')
            .get();
        
        int updatedCount = 0;
        for (QueryDocumentSnapshot menuItemDoc in menuItemsSnapshot.docs) {
          Map<String, dynamic> menuItemData = menuItemDoc.data() as Map<String, dynamic>;
          String currentVendorId = menuItemData['vendor_id'] ?? '';
          
          // Check if this menu item should belong to this vendor
          // This is a heuristic approach - in a real app, you'd have better mapping
          if (currentVendorId.contains('vendor') || 
              currentVendorId.contains('test_vendor') ||
              currentVendorId.startsWith('vendor')) {
            
            // Update the menu item to use the correct Firebase UID
            await _firestore.collection('menu_items').doc(menuItemDoc.id).update({
              'vendor_id': firebaseUid,
              'updated_at': FieldValue.serverTimestamp(),
            });
            
            updatedCount++;
            print('Updated menu item: ${menuItemData['name']} to use vendor ID: $firebaseUid');
          }
        }
        
        // Also update any existing orders with the wrong vendor ID
        QuerySnapshot ordersSnapshot = await _firestore
            .collection('orders')
            .where('vendor_id', isEqualTo: 'vendor4') // Update this specific vendor ID
            .get();
        
        for (QueryDocumentSnapshot orderDoc in ordersSnapshot.docs) {
          await _firestore.collection('orders').doc(orderDoc.id).update({
            'vendor_id': firebaseUid,
            'updated_at': FieldValue.serverTimestamp(),
          });
          print('Updated order: ${orderDoc.id} to use vendor ID: $firebaseUid');
        }
        
        print('Updated $updatedCount menu items for vendor: $vendorName');
      }
      
      print('Vendor ID mismatch fix completed successfully!');
    } catch (e) {
      print('Error fixing vendor ID mismatch: $e');
      throw Exception('Failed to fix vendor ID mismatch: $e');
    }
  }
}
