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
import 'package:campus_food_app/providers/notification_provider.dart';
import 'package:campus_food_app/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Campus Food App',
        theme: AppTheme.getThemeData(),
        initialRoute: '/',
        routes: AppRoutes.getRoutes(),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

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
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  final role = userData?['role'];
                  
                  // Initialize providers with user data
                  userProvider.fetchUser();
                  
                  // Initialize cart and other providers for non-vendor/admin users
                  if (role != 'vendor' && role != 'admin') {
                    // Initialize cart
                    Provider.of<CartProvider>(context, listen: false).initCart(user.uid);
                    
                    // Fetch user orders
                    Provider.of<OrderProvider>(context, listen: false).fetchUserOrders(user.uid);
                    
                    // Initialize notifications
                    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                    notificationProvider.fetchUserNotifications(user.uid);
                    notificationProvider.startListeningToNotifications(user.uid);
                    
                    // Fetch vendors for student view
                    Provider.of<VendorProvider>(context, listen: false).fetchAllVendors();
                  }
                  
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
                  child: CircularProgressIndicator(),
                ),
              );
            },
          );
        }
        
        // While waiting for auth state, show loading
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}