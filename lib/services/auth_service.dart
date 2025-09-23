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

  // Ensure user document exists in Firestore
  Future<Map<String, dynamic>> ensureUserDocument(String uid, {String? email, String? role}) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        print('User document found for: $uid');
        return doc.data()!;
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
        
        await _firestore.collection('users').doc(uid).set(userData);
        print('User document created successfully for: $uid with role: ${role ?? 'student'}');
        return userData;
      }
    } catch (e) {
      print('Error ensuring user document: $e');
      // Return a default user document even if there's an error
      return {
        'email': email ?? 'unknown@example.com',
        'role': role ?? 'student',
        'wallet_balance': 0.0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
    }
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
        'phone': '1234567890',
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
        'phone': '1234567890',
        'campus_id': 'VENDOR001',
      });

      print('Test vendor account created successfully');
      return userCredential.user;
    } catch (e) {
      print('Error creating test vendor account: $e');
      return null;
    }
  }
}