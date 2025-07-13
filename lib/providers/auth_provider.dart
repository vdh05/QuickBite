import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/address.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;

  List<Address> _addresses = [];
  bool _hasSetupAddress = false;

  List<Address> get addresses => [..._addresses];
  bool get hasSetupAddress => _hasSetupAddress;

  // Add additional user data fields
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  Map<String, dynamic>? _userProfile;
  bool _hasAddress = false;

  // Getters for user data
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  Map<String, dynamic>? get userProfile => _userProfile;

  // Check if user is already logged in
  Future<bool> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      return false;
    }

    _token = prefs.getString('token');
    _userId = prefs.getString('userId');
    _userName = prefs.getString('userName');
    _userEmail = prefs.getString('userEmail');
    _userPhone = prefs.getString('userPhone');
    _hasAddress = prefs.getBool('hasAddress') ?? false;

    // Load complete profile if available
    if (prefs.containsKey('userProfile')) {
      final profileJson = prefs.getString('userProfile');
      if (profileJson != null) {
        _userProfile = jsonDecode(profileJson) as Map<String, dynamic>;
      }
    }

    // Set token in ApiService
    ApiService.setToken(_token);

    notifyListeners();
    return true;
  }

  // Login user with improved error handling
  Future<bool> login(String email, String password) async {
    try {
      print("Attempting login for: $email");
      final response = await ApiService.loginUser(email, password);

      print("Login response data: $response"); // Add this for debugging

      if (response.containsKey('token') && response['token'] != null) {
        _token = response['token'];

        // Set token in ApiService
        ApiService.setToken(_token);

        // Extract user data, handling different response structures
        if (response.containsKey('user')) {
          _userData = response['user'];
          
          // Make sure we extract the real name from the user data
          _userName = _userData?['name'];
          _userEmail = _userData?['email'];
          _userPhone = _userData?['phone'];
          _userId = _userData?['id'];
          
          print("User data extracted: Name=$_userName, Email=$_userEmail");
        } else {
          // If user data is at the top level, extract relevant fields
          _userData = {
            'name': response['name'],
            'email': response['email'],
            'phone': response['phone'],
            // Add other fields as needed
          };
          
          _userName = response['name'];
          _userEmail = response['email'];
          _userPhone = response['phone'];
        }

        _isAuthenticated = true;

        // Save token to SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('token', _token!);
        } catch (e) {
          print("SharedPreferences error (non-critical): $e");
          // Continue with login even if SharedPreferences fails
        }

        // Check if user has addresses
        try {
          final addressesResponse = await ApiService.getUserAddresses();
          if (addressesResponse.isNotEmpty) {
            _addresses = addressesResponse;
            _hasSetupAddress = true;
          } else {
            _hasSetupAddress = false;
          }
        } catch (e) {
          print("Failed to fetch addresses: $e");
          _hasSetupAddress = false;
        }

        // Save user data
        if (response['user'] != null) {
          final userData = response['user'];
          _userId = userData['id'] ?? '';
          _userName = userData['name'] ?? '';
          _userEmail = userData['email'] ?? '';
          _userPhone = userData['phone'] ?? '';
          _userProfile = userData;

          // Check if user has address
          _hasAddress = userData['hasAddress'] == true;

          // Save user data to storage
          await _saveUserData();
        }

        notifyListeners();
        return true;
      } else {
        print("Login failed: No token in response");
        return false;
      }
    } catch (e) {
      print("Login error: $e");

      // Special case: If we got user data but SharedPreferences failed
      if (e.toString().contains('MissingPluginException') &&
          e.toString().contains('shared_preferences')) {
        // Set authenticated state even without persistent storage
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }

      return false;
    }
  }

  // Register user
  Future<bool> register(String name, String email, String phone, String password) async {
    try {
      final response = await ApiService.registerUser({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      });

      // If we get a response object, consider it a success even if no token
      if (response != null) {
        // Check if token is present in response
        if (response.containsKey('token') && response['token'] != null) {
          _token = response['token'];
          _userData = response['user'];
          _isAuthenticated = true;

          // Save token to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('token', _token!);

          notifyListeners();
        }
        // Return true regardless of token - user was created
        return true;
      }
      return false;
    } catch (e) {
      print("Registration error: $e");
      // Check if error message indicates that user was created
      if (e.toString().contains('User already exists') ||
          e.toString().contains('already registered')) {
        // If error is just that user already exists, still consider it "successful"
        return true;
      }
      return false;
    }
  }

  // Method to save user address
  Future<bool> saveUserAddress(Map<String, dynamic> addressData) async {
    try {
      final response = await ApiService.addUserAddress(addressData);
      _hasAddress = true;

      // Create an Address object and add it to the addresses list
      final newAddress = Address.fromJson(response);
      if (!_addresses.any((addr) => addr.id == newAddress.id)) {
        _addresses.add(newAddress);
      }
      
      // Set the flag indicating user has set up an address
      _hasSetupAddress = true;

      // Update user profile if available
      if (_userProfile != null) {
        _userProfile!['hasAddress'] = true;
        await _saveUserData();
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error saving address: $e');
      return false;
    }
  }

  // Method to save user data to local storage
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save token
    if (_token != null) {
      await prefs.setString('token', _token!);
    }

    // Save user data
    if (_userId != null) await prefs.setString('userId', _userId!);
    if (_userName != null) await prefs.setString('userName', _userName!);
    if (_userEmail != null) await prefs.setString('userEmail', _userEmail!);
    if (_userPhone != null) await prefs.setString('userPhone', _userPhone!);
    if (_hasAddress != null) await prefs.setBool('hasAddress', _hasAddress);

    // Save complete user profile as JSON
    if (_userProfile != null) {
      await prefs.setString('userProfile', jsonEncode(_userProfile));
    }
  }

  // Enhanced method to load user data from local storage
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('token')) {
      return false;
    }

    _token = prefs.getString('token');
    _userId = prefs.getString('userId');
    _userName = prefs.getString('userName');
    _userEmail = prefs.getString('userEmail');
    _userPhone = prefs.getString('userPhone');
    _hasAddress = prefs.getBool('hasAddress') ?? false;

    // Load complete profile if available
    if (prefs.containsKey('userProfile')) {
      final profileJson = prefs.getString('userProfile');
      if (profileJson != null) {
        _userProfile = jsonDecode(profileJson) as Map<String, dynamic>;
      }
    }

    // Load user's addresses
    try {
      final addressesResponse = await ApiService.getUserAddresses();
      if (addressesResponse.isNotEmpty) {
        _addresses = addressesResponse;
        _hasSetupAddress = true;
      }
    } catch (e) {
      print("Failed to fetch addresses during auto-login: $e");
    }

    // Set token in ApiService
    ApiService.setToken(_token);

    notifyListeners();
    return true;
  }

  // Enhanced logout method to clear all user data
  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    _userProfile = null;
    _hasAddress = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    ApiService.setToken(null);
    notifyListeners();
  }

  // Add new address
  Future<bool> addAddress(Address address) async {
    try {
      final newAddress = await ApiService.addUserAddress(address.toJson());
      _addresses.add(Address.fromJson(newAddress));
      _hasSetupAddress = true;
      notifyListeners();
      return true;
    } catch (e) {
      print("Failed to add address: $e");
      return false;
    }
  }
}
