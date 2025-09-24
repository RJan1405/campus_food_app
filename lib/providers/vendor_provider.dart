import 'package:flutter/foundation.dart';
import 'package:campus_food_app/models/vendor_model.dart';
import 'package:campus_food_app/models/menu_item_model.dart';
import 'package:campus_food_app/services/vendor_service.dart';

class VendorProvider with ChangeNotifier {
  List<VendorModel> _vendors = [];
  VendorModel? _selectedVendor;
  List<MenuItemModel> _menuItems = [];
  bool _isLoading = false;
  final VendorService _vendorService = VendorService();

  List<VendorModel> get vendors => _vendors;
  VendorModel? get selectedVendor => _selectedVendor;
  List<MenuItemModel> get menuItems => _menuItems;
  bool get isLoading => _isLoading;

  Future<void> fetchAllVendors() async {
    _isLoading = true;
    notifyListeners();

    try {
      _vendors = await _vendorService.getAllVendors();
    } catch (e) {
      print('Error fetching vendors: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchVendorById(String vendorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedVendor = await _vendorService.getVendorById(vendorId);
      await fetchMenuItems(vendorId);
    } catch (e) {
      print('Error fetching vendor: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMenuItems(String vendorId) async {
    try {
      _menuItems = await _vendorService.getMenuItems(vendorId);
      notifyListeners();
    } catch (e) {
      print('Error fetching menu items: $e');
    }
  }

  // Refresh vendor data to get updated ratings
  Future<void> refreshVendorData() async {
    if (_selectedVendor != null) {
      await fetchVendorById(_selectedVendor!.id);
    }
    await fetchAllVendors();
  }

  Future<void> searchVendors(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      _vendors = await _vendorService.searchVendors(query);
    } catch (e) {
      print('Error searching vendors: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedVendor() {
    _selectedVendor = null;
    _menuItems = [];
    notifyListeners();
  }
}