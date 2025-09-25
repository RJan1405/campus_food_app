import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  Future<User?> signUp(String email, String password, String role) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Create a user document in Firestore
      print('Creating user document with role: $role for user: ${userCredential.user!.uid}');
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role, // e.g., 'student' or 'vendor'
        'wallet_balance': 0.0,
        'created_at': FieldValue.serverTimestamp(),
      });
      print('User document created successfully with role: $role');
      
      // If user is registering as a vendor, create a vendor document
      if (role == 'vendor') {
        await _createVendorDocument(userCredential.user!.uid, email);
      }
      
      return userCredential.user;
    } catch (e) {
      print('SignUp Error: $e');
      
      // Handle specific Firebase Auth errors
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('This email is already registered. Please use a different email or try logging in.');
          case 'weak-password':
            throw Exception('Password is too weak. Please choose a stronger password.');
          case 'invalid-email':
            throw Exception('Please enter a valid email address.');
          case 'operation-not-allowed':
            throw Exception('Email/Password authentication is not enabled. Please contact support.');
          default:
            throw Exception('Sign up failed: ${e.message}');
        }
      }
      
      // Handle other errors
      if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        throw Exception('Firebase Authentication is not configured. Please contact support.');
      }
      
      // Handle Firebase type casting issues (known Firebase package bug)
      if (e.toString().contains('type \'List<Object?>\' is not a subtype of type \'PigeonUserDetails?\'')) {
        print('Firebase type casting warning (non-critical): $e');
        // Authentication still works despite this warning, but we need to return the user
        // Try to get the current user from Firebase Auth
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('Recovered user from Firebase Auth after type casting error: ${currentUser.uid}');
          // Still create the user document
          await _firestore.collection('users').doc(currentUser.uid).set({
            'email': email,
            'role': role,
            'wallet_balance': 0.0,
            'created_at': FieldValue.serverTimestamp(),
          });
          print('User document created successfully with role: $role after recovery');
          return currentUser;
        }
        return null;
      }
      
      throw Exception('Sign up failed. Please try again.');
    }
  }

  // Sign up with complete details (for OTP verification flow)
  Future<User?> signUpWithDetails({
    required String email,
    required String password,
    required String role,
    required String name,
    required String phoneNumber,
    required String campusId,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create a user document in Firestore with complete details
      print('Creating user document with role: $role for user: ${userCredential.user!.uid}');
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role,
        'name': name,
        'phone_number': phoneNumber,
        'campus_id': campusId,
        'wallet_balance': 0.0,
        'email_verified': true, // Mark as verified since OTP was verified
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      print('User document created successfully with role: $role');
      
      // If user is registering as a vendor, create a vendor document
      if (role == 'vendor') {
        await _createVendorDocument(userCredential.user!.uid, email, name, phoneNumber);
      }
      
      return userCredential.user;
    } catch (e) {
      print('SignUp Error: $e');
      
      // Handle specific Firebase Auth errors
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('This email is already registered. Please use a different email or try logging in.');
          case 'weak-password':
            throw Exception('Password is too weak. Please choose a stronger password.');
          case 'invalid-email':
            throw Exception('Please enter a valid email address.');
          case 'operation-not-allowed':
            throw Exception('Email/Password authentication is not enabled. Please contact support.');
          default:
            throw Exception('Sign up failed: ${e.message}');
        }
      }
      
      // Handle other errors
      if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        throw Exception('Firebase Authentication is not configured. Please contact support.');
      }
      
      // Handle Firebase type casting issues (known Firebase package bug)
      if (e.toString().contains('type \'List<Object?>\' is not a subtype of type \'PigeonUserDetails?\'')) {
        print('Firebase type casting warning (non-critical): $e');
        // Authentication still works despite this warning, but we need to return the user
        // Try to get the current user from Firebase Auth
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('Recovered user from Firebase Auth after type casting error: ${currentUser.uid}');
          // Still create the user document
          await _firestore.collection('users').doc(currentUser.uid).set({
            'email': email,
            'role': role,
            'name': name,
            'phone_number': phoneNumber,
            'campus_id': campusId,
            'wallet_balance': 0.0,
            'email_verified': true,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
          print('User document created successfully with role: $role after recovery');
          return currentUser;
        }
        return null;
      }
      
      throw Exception('Sign up failed. Please try again.');
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');
      
      // Add timeout to prevent long waiting
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Login timeout. Please check your internet connection and try again.');
        },
      );
      
      print('Sign in successful for user: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      print('SignIn Error: $e');
      print('Error type: ${e.runtimeType}');
      
      // Handle specific Firebase Auth errors
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception('No account found with this email. Please check your email or sign up.');
          case 'wrong-password':
            throw Exception('Incorrect password. Please try again.');
          case 'invalid-email':
            throw Exception('Please enter a valid email address.');
          case 'user-disabled':
            throw Exception('This account has been disabled. Please contact support.');
          case 'too-many-requests':
            throw Exception('Too many failed attempts. Please try again later.');
          case 'invalid-credential':
            throw Exception('Invalid email or password. Please check your credentials and try again.');
          default:
            throw Exception('Login failed: ${e.message}');
        }
      }
      
      // Handle other errors
      if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        throw Exception('Firebase Authentication is not configured. Please contact support.');
      }
      
      // Handle Firebase type casting issues (known Firebase package bug)
      if (e.toString().contains('type \'List<Object?>\' is not a subtype of type \'PigeonUserDetails?\'')) {
        print('Firebase type casting warning (non-critical): $e');
        // Authentication still works despite this warning, try to get the current user
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('Recovered user from Firebase Auth after type casting error: ${currentUser.uid}');
          return currentUser;
        }
        return null;
      }
      
      throw Exception('Login failed. Please try again.');
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    clearCache(); // Clear cache on logout
    print('User signed out successfully');
  }

  // Clear all auth state (useful for debugging)
  Future<void> clearAuthState() async {
    await _auth.signOut();
    // Force clear any cached auth state
    await _auth.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }
  
  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Cache for user documents
  static final Map<String, Map<String, dynamic>> _userDocumentCache = {};
  
  // Clear cache (useful for logout)
  static void clearCache() {
    _userDocumentCache.clear();
    print('User document cache cleared');
  }
  
  // Ensure user document exists in Firestore with caching and robust fallback
  Future<Map<String, dynamic>> ensureUserDocument(String uid, {String? email, String? role}) async {
    try {
      // Check cache first
      if (_userDocumentCache.containsKey(uid)) {
        print('User document found in cache for: $uid');
        return _userDocumentCache[uid]!;
      }
      
      // Try to check Firestore with timeout and retry logic
      try {
        // First check if user is an admin with timeout
        final adminDoc = await _firestore.collection('admins').doc(uid).get().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            throw TimeoutException('Firestore admin check timeout', const Duration(seconds: 3));
          },
        );
        
        if (adminDoc.exists) {
          print('Admin document found for: $uid');
          final adminData = adminDoc.data()!;
          final userData = {
            'email': adminData['email'] ?? email ?? 'unknown@example.com',
            'role': 'admin',
            'name': adminData['name'] ?? 'Admin',
            'is_active': adminData['is_active'] ?? true,
            'created_at': adminData['created_at'],
            'updated_at': adminData['updated_at'],
          };
          _userDocumentCache[uid] = userData;
          return userData;
        }
        
        // Check regular users collection with timeout
        final doc = await _firestore.collection('users').doc(uid).get().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            throw TimeoutException('Firestore user check timeout', const Duration(seconds: 3));
          },
        );
        
        if (doc.exists) {
          print('User document found for: $uid');
          final userData = doc.data()!;
          _userDocumentCache[uid] = userData;
          return userData;
        } else {
          // Create user document if it doesn't exist
          print('Creating missing user document for: $uid');
          final userData = {
            'email': email ?? 'unknown@example.com',
            'role': role ?? 'student',
            'wallet_balance': 0.0,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          };
          
          await _firestore.collection('users').doc(uid).set(userData).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('Firestore create timeout, using local data');
            },
          );
          print('User document created successfully for: $uid with role: ${role ?? 'student'}');
          _userDocumentCache[uid] = userData;
          return userData;
        }
      } catch (e) {
        print('Firestore unavailable, using offline fallback: $e');
        // Firestore is unavailable, use offline fallback
        return await _getOfflineUserDocument(uid, email: email, role: role);
      }
    } catch (e) {
      print('Error ensuring user document: $e');
      // Return offline fallback even if there's an error
      return await _getOfflineUserDocument(uid, email: email, role: role);
    }
  }
  
  // Get user document from offline/local storage
  Future<Map<String, dynamic>> _getOfflineUserDocument(String uid, {String? email, String? role}) async {
    print('Using offline user document for: $uid');
    
    // Try to determine if this might be an admin based on email
    bool isAdmin = false;
    if (email != null) {
      isAdmin = email == 'admin@campus.com' || email.endsWith('@admin.campus.com');
    }
    
    final userData = {
      'email': email ?? 'unknown@example.com',
      'role': isAdmin ? 'admin' : (role ?? 'student'),
      'wallet_balance': 0.0,
      'name': isAdmin ? 'Admin' : (email?.split('@')[0] ?? 'User'),
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'offline_mode': true, // Flag to indicate this is offline data
    };
    
    _userDocumentCache[uid] = userData;
    return userData;
  }
  
  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
  
  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print(e.toString());
    }
  }

  // Check if user exists in Firestore
  Future<bool> userExists(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Create a test account for debugging
  Future<User?> createTestAccount() async {
    try {
      const testEmail = 'test@campusfood.com';
      const testPassword = 'test123456';
      
      // Check if test account already exists
      final existingUser = await _auth.fetchSignInMethodsForEmail(testEmail);
      if (existingUser.isNotEmpty) {
        print('Test account already exists');
        return null;
      }

      // Create test account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': testEmail,
        'role': 'student',
        'wallet_balance': 100.0,
        'name': 'Test User',
        'phone_number': '1234567890',
        'campus_id': 'TEST001',
      });

      print('Test account created successfully');
      return userCredential.user;
    } catch (e) {
      print('Error creating test account: $e');
      return null;
    }
  }

  // Create a test vendor account for debugging
  Future<User?> createTestVendorAccount() async {
    try {
      const testEmail = 'vendor@campusfood.com';
      const testPassword = 'vendor123456';
      
      // Check if test vendor account already exists
      final existingUser = await _auth.fetchSignInMethodsForEmail(testEmail);
      if (existingUser.isNotEmpty) {
        print('Test vendor account already exists');
        return null;
      }

      // Create test vendor account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      // Create user document in Firestore with vendor role
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': testEmail,
        'role': 'vendor',
        'wallet_balance': 0.0,
        'name': 'Test Vendor',
        'phone_number': '1234567890',
        'campus_id': 'VENDOR001',
      });

      // Create vendor document
      await _createVendorDocument(userCredential.user!.uid, testEmail, 'Test Vendor');

      print('Test vendor account created successfully');
      return userCredential.user;
    } catch (e) {
      print('Error creating test vendor account: $e');
      return null;
    }
  }

  // Create a vendor document in the vendors collection
  Future<void> _createVendorDocument(String userId, String email, [String? name, String? phoneNumber]) async {
    try {
      // Extract vendor name from email if not provided
      String vendorName = name ?? email.split('@')[0].replaceAll('.', ' ').split(' ').map((word) => 
        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
      ).join(' ');

      await _firestore.collection('vendors').doc(userId).set({
        'name': vendorName,
        'description': 'Welcome to $vendorName! We serve delicious food.',
        'location': 'Campus Food Court',
        'phone_number': phoneNumber ?? 'Not provided',
        'owner_id': userId,
        'is_open': true,
        'food_types': ['Fast Food', 'Beverages'],
        'image_url': null,
        'rating': 0.0,
        'total_ratings': 0,
        'is_approved': false, // New vendors need approval
        'approval_status': 'pending', // Pending approval by default
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('Vendor document created successfully for user: $userId');
    } catch (e) {
      print('Error creating vendor document: $e');
      throw Exception('Failed to create vendor profile: $e');
    }
  }

  // Create vendor document with complete user data
  Future<void> createVendorWithUserData(String userId, String email, String name, String phone, String campusId) async {
    try {
      await _firestore.collection('vendors').doc(userId).set({
        'name': name,
        'description': 'Welcome to $name! We serve delicious food.',
        'location': 'Campus Food Court',
        'owner_id': userId,
        'is_open': true,
        'food_types': ['Fast Food', 'Beverages'],
        'image_url': null,
        'rating': 0.0,
        'total_ratings': 0,
        'phone_number': phone,
        'campus_id': campusId,
        'is_approved': false, // New vendors need approval
        'approval_status': 'pending', // Pending approval by default
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('Vendor document created successfully for user: $userId with name: $name');
    } catch (e) {
      print('Error creating vendor document: $e');
      throw Exception('Failed to create vendor profile: $e');
    }
  }

  // Check if user is vendor (and approved)
  Future<bool> isVendor() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final vendorDoc = await _firestore
          .collection('vendors')
          .doc(user.uid)
          .get();

      if (!vendorDoc.exists) return false;

      // Check if vendor is approved
      final vendorData = vendorDoc.data()!;
      return vendorData['is_approved'] == true;
    } catch (e) {
      print('Error checking vendor status: $e');
      return false;
    }
  }

  // Get vendor approval status
  Future<String> getVendorApprovalStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'not_vendor';

      final vendorDoc = await _firestore
          .collection('vendors')
          .doc(user.uid)
          .get();

      if (!vendorDoc.exists) return 'not_vendor';

      final vendorData = vendorDoc.data()!;
      return vendorData['approval_status'] ?? 'pending';
    } catch (e) {
      print('Error getting vendor approval status: $e');
      return 'error';
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      return adminDoc.exists && adminDoc.data()?['is_active'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Reset password for any user (including admin)
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
    } catch (e) {
      print('Error sending password reset email: $e');
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception('No account found with this email address.');
          case 'invalid-email':
            throw Exception('Please enter a valid email address.');
          case 'too-many-requests':
            throw Exception('Too many password reset attempts. Please try again later.');
          default:
            throw Exception('Failed to send password reset email: ${e.message}');
        }
      }
      
      throw Exception('Failed to send password reset email: $e');
    }
  }
}