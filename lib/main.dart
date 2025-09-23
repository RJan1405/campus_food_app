import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:campus_food_app/firebase_options.dart';
import 'package:campus_food_app/routes.dart';
import 'package:campus_food_app/screens/auth/login_screen.dart';
import 'package:campus_food_app/screens/student/home_screen.dart';
import 'package:campus_food_app/screens/vendor/dashboard_screen.dart';
import 'package:campus_food_app/screens/admin/dashboard_screen.dart';
import 'package:campus_food_app/providers/user_provider.dart';
import 'package:campus_food_app/providers/cart_provider.dart';
import 'package:campus_food_app/providers/order_provider.dart';
import 'package:campus_food_app/providers/vendor_provider.dart';
import 'package:campus_food_app/services/auth_service.dart';
// import 'package:campus_food_app/providers/notification_provider.dart';  // Temporarily disabled
import 'package:campus_food_app/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only if not already initialized
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized, continue
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
        // ChangeNotifierProvider(create: (_) => NotificationProvider()),  // Temporarily disabled
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CampusBites',
        theme: AppTheme.getThemeData(),
        initialRoute: '/',
        routes: AppRoutes.getRoutes(),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  int _retryCount = 0;
  static const int _maxRetries = 3;

  // Ensure user document exists in Firestore with retry mechanism
  Future<Map<String, dynamic>> _ensureUserDocumentExists(User user) async {
    final authService = AuthService();
    
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        print('Attempting to ensure user document exists for user: ${user.uid} (attempt ${attempt + 1}/$_maxRetries)');
        
        final userData = await authService.ensureUserDocument(
          user.uid,
          email: user.email,
          role: 'student', // Default role, will be updated if user document exists
        );
        
        print('User document found/created successfully for user: ${user.uid}');
        return userData;
      } catch (e) {
        print('Error ensuring user document exists (attempt ${attempt + 1}): $e');
        
        // Wait before retrying
        if (attempt < _maxRetries - 1) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1))); // Exponential backoff
        }
      }
    }
    
    // If all retries failed, return a default user document
    print('All retry attempts failed, returning default user document for: ${user.uid}');
    return {
      'email': user.email ?? 'unknown@example.com',
      'role': 'student',
      'wallet_balance': 0.0,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Access user provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          
          // User is logged in, check their role
          return FutureBuilder<Map<String, dynamic>>(
            future: _ensureUserDocumentExists(user),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      // If there's an error, show error message and retry
                      print('Error fetching user data: ${snapshot.error}');
                      
                      return Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              const Text('Error loading user data'),
                              const SizedBox(height: 8),
                              Text('${snapshot.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // Navigate back to login to retry
                                  Navigator.of(context).pushReplacementNamed('/');
                                },
                                child: const Text('Back to Login'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                
                    if (snapshot.hasData) {
                      final userData = snapshot.data!;
                      final role = userData['role'];
                      print('User role detected: $role for user: ${user.uid}');
                  
                      // Initialize providers with user data - use WidgetsBinding to avoid setState during build
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        userProvider.fetchUser();

                        // Initialize cart and other providers for non-vendor/admin users
                        if (role != 'vendor' && role != 'admin') {
                          // Initialize cart
                          Provider.of<CartProvider>(context, listen: false).initCart(user.uid);

                          // Fetch user orders
                          Provider.of<OrderProvider>(context, listen: false).fetchUserOrders(user.uid);

                          // Initialize notifications - temporarily disabled
                          // final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                          // notificationProvider.fetchUserNotifications(user.uid);
                          // notificationProvider.startListeningToNotifications(user.uid);

                          // Fetch vendors for student view
                          Provider.of<VendorProvider>(context, listen: false).fetchAllVendors();
                        }
                      });
                  
                  if (role == 'vendor') {
                    return const DashboardScreen();
                  } else if (role == 'admin') {
                    return const AdminDashboardScreen();
                  } else {
                    return const HomeScreen();
                  }
                }
              }
              
              // While waiting for Firestore data, show loading
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading user data...'),
                    ],
                  ),
                ),
              );
            },
          );
        }
        
        // While waiting for auth state, show loading
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing app...'),
              ],
            ),
          ),
        );
      },
    );
  }
}