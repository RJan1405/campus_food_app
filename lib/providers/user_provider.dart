import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_food_app/models/user_model.dart';
import 'package:campus_food_app/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> fetchUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        
        if (userDoc.exists) {
          _user = UserModel.fromFirestore(userDoc);
        }
      }
    } catch (e) {
      print('Error fetching user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserWalletBalance(double newBalance) async {
    if (_user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'wallet_balance': newBalance});
        
        // Update local user model
        _user = UserModel(
          uid: _user!.uid,
          email: _user!.email,
          role: _user!.role,
          walletBalance: newBalance,
          name: _user!.name,
          phoneNumber: _user!.phoneNumber,
          campusId: _user!.campusId,
          favoriteVendors: _user!.favoriteVendors,
        );
        
        notifyListeners();
      } catch (e) {
        print('Error updating wallet balance: $e');
      }
    }
  }

  Future<void> toggleFavoriteVendor(String vendorId) async {
    if (_user != null) {
      try {
        List<String> updatedFavorites = _user!.favoriteVendors?.toList() ?? [];
        
        if (updatedFavorites.contains(vendorId)) {
          updatedFavorites.remove(vendorId);
        } else {
          updatedFavorites.add(vendorId);
        }
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'favorite_vendors': updatedFavorites});
        
        // Update local user model
        _user = UserModel(
          uid: _user!.uid,
          email: _user!.email,
          role: _user!.role,
          walletBalance: _user!.walletBalance,
          name: _user!.name,
          phoneNumber: _user!.phoneNumber,
          campusId: _user!.campusId,
          favoriteVendors: updatedFavorites,
        );
        
        notifyListeners();
      } catch (e) {
        print('Error toggling favorite vendor: $e');
      }
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}