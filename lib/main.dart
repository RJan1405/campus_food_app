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
import 'package:campus_food_app/screens/admin/admin_dashboard_screen.dart';
import 'package:campus_food_app/screens/vendor/vendor_status_screen.dart';
import 'package:campus_food_app/providers/user_provider.dart';
import 'package:campus_food_app/providers/cart_provider.dart';
import 'package:campus_food_app/providers/order_provider.dart';
import 'package:campus_food_app/providers/vendor_provider.dart';
import 'package:campus_food_app/services/auth_service.dart';
import 'package:campus_food_app/services/admin_service.dart';
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
  
  // Create default admin account if it doesn't exist
  await _createDefaultAdmin();
  
  runApp(const MyApp());
}

// Create default admin account
Future<void> _createDefaultAdmin() async {
  try {
    final authService = AuthService();
    final adminService = AdminService();
    
    // Check if admin already exists
    final adminExists = await authService.isAdmin();
    if (adminExists) {
      print('Default admin already exists');
      return;
    }
    
    // Create default admin account
    print('Creating default admin account...');
    await adminService.createSuperAdmin(
      email: 'admin@campus.com',
      password: 'admin123456',
      name: 'Campus Admin',
    );
    print('Default admin created successfully!');
    print('Admin Credentials:');
    print('Email: admin@campus.com');
    print('Password: admin123456');
  } catch (e) {
    print('Error creating default admin: $e');
    // Continue app startup even if admin creation fails
  }
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

  // Cache for user documents to avoid repeated calls
  static final Map<String, Map<String, dynamic>> _userDocumentCache = {};
  
        // Ensure user document exists in Firestore with caching and robust fallback
        Future<Map<String, dynamic>> _ensureUserDocumentExists(User user) async {
          // Check cache first
          if (_userDocumentCache.containsKey(user.uid)) {
            print('User document found in cache for: ${user.uid}');
            return _userDocumentCache[user.uid]!;
          }
          
          final authService = AuthService();
          
          try {
            print('Attempting to ensure user document exists for user: ${user.uid}');
            
            final userData = await authService.ensureUserDocument(
              user.uid,
              email: user.email,
              role: 'student', // Default role, will be updated if user document exists
            );
            
            // Cache the result
            _userDocumentCache[user.uid] = userData;
            
            print('User document found/created successfully for user: ${user.uid}');
            return userData;
          } catch (e) {
            print('Error ensuring user document exists: $e');
            
            // Return a default user document with offline fallback
            print('Using offline fallback for user: ${user.uid}');
            
            // Determine if this might be an admin
            bool isAdmin = false;
            if (user.email != null) {
              isAdmin = user.email == 'admin@campus.com' || user.email!.endsWith('@admin.campus.com');
            }
            
            final defaultData = {
              'email': user.email ?? 'unknown@example.com',
              'role': isAdmin ? 'admin' : 'student',
              'wallet_balance': 0.0,
              'name': isAdmin ? 'Admin' : (user.email?.split('@')[0] ?? 'User'),
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'offline_mode': true,
            };
            
            // Cache the default data
            _userDocumentCache[user.uid] = defaultData;
            return defaultData;
          }
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
                    // Check if vendor is approved
                    return FutureBuilder<bool>(
                      future: AuthService().isVendor(),
                      builder: (context, vendorSnapshot) {
                        if (vendorSnapshot.connectionState == ConnectionState.done) {
                          if (vendorSnapshot.data == true) {
                            return const DashboardScreen();
                          } else {
                            // Vendor not approved, show status screen
                            return const VendorStatusScreen();
                          }
                        }
                        return const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    );
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