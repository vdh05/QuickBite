import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../models/address.dart';

class ApiService {
  // Use the correct IP address based on platform
  static String get baseUrl {
    if (Platform.isAndroid) {
      // 10.0.2.2 is the special IP for Android emulator to reach host machine
      return 'http://10.0.2.2:5000/api';  // Change localhost to 10.0.2.2 for Android
    } else if (Platform.isIOS) {
      // For iOS simulator
      return 'http://localhost:5000/api';
    } else {
      // For web or desktop
      return 'http://localhost:5000/api';
    }
  }
  
  // Static token variable that can be set by the AuthProvider
  static String? _authToken;
  
  // Setter for the token
  static void setToken(String? token) {
    _authToken = token;
  }
  
  // Getter for authorization headers
  static Map<String, String> get _headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  static Future<List<Restaurant>> getRestaurants() async {
    try {
      print("Making HTTP request to: $baseUrl/restaurants");
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body.substring(0, min(100, response.body.length))}...");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Restaurant.fromJson(json)).toList();
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print("Exception in getRestaurants: $e");
      print("Stack trace: $stackTrace");
      
      // Temporarily return sample data for testing when API fails
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Connection refused')) {
        print("Returning sample data due to connection issue");
        return _getSampleRestaurants();
      }
      
      throw Exception('Failed to load restaurants: $e');
    }
  }
  
  // Get menu items for a specific restaurant
  static Future<List<MenuItem>> getMenuForRestaurant(String restaurantId) async {
    try {
      print("Fetching menu items for restaurant: $restaurantId");
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/$restaurantId/menu'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print("Menu API response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MenuItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load menu items (${response.statusCode})');
      }
    } catch (e) {
      print("Error fetching menu: $e");
      
      // Return sample menu items for testing
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Connection refused')) {
        return _getSampleMenuItems(restaurantId);
      }
      
      throw Exception('Failed to load menu: $e');
    }
  }
  
  // Register user with better error handling
  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
    try {
      print("Registering user with data: ${userData['email']}");
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 15));
      
      print("Registration response status: ${response.statusCode}");
      print("Registration response body: ${response.body}");
      
      final responseData = jsonDecode(response.body);
      
      // Consider a range of success codes (not just 201)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        // If backend created user but returned an error, extract message
        final message = responseData['message'] ?? 'Unknown error occurred';
        
        // If the message suggests user was created but some other issue occurred
        if (message.toString().toLowerCase().contains('already exists') ||
            response.statusCode == 409) {
          // Return a custom response for existing user
          return {
            'message': 'User already exists',
            'exists': true
          };
        }
        
        throw Exception('Failed to register user (${response.statusCode}): $message');
      }
    } catch (e) {
      print("Error registering user: $e");
      
      // For debugging only - in production remove this mock data
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Connection refused')) {
        // Return mock success for testing without backend
        return {
          'token': 'mock_token_for_testing',
          'user': {
            'id': 'test_id',
            'name': userData['name'],
            'email': userData['email'],
            'phone': userData['phone'],
          },
          'message': 'Registration successful (mock)'
        };
      }
      
      rethrow;
    }
  }

  // Login user with better error handling
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      print("Sending login request to: ${baseUrl}/auth/login");
      print("Login credentials: $email (password not logged)");
      
      final response = await http.post(
        Uri.parse('${baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));
      
      print("Login response status: ${response.statusCode}");
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? 'Unknown error occurred';
        throw Exception('Login failed (${response.statusCode}): $message');
      }
    } catch (e) {
      print("Error during login API call: $e");
      
      // Check for specific error messages
      if (e.toString().contains('TimeoutException')) {
        print("Server connection timed out. Using mock data for testing.");
      } else if (e.toString().contains('SocketException') || 
                e.toString().contains('Connection refused')) {
        print("Server connection failed. Using mock data for testing.");
      }
      
      // For debugging/testing without backend
      // Extract username from email for more realistic test data
      String userName = email.split('@').first;
      userName = userName.split('.').map((part) => 
        part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : part
      ).join(' ');
      
      // Return mock success response for testing with more relevant name
      return {
        'token': 'mock_token_for_testing',
        'user': {
          'id': 'test_id',
          'name': userName, // Use extracted name instead of "Test User"
          'email': email,
        },
        'message': 'Login successful (mock)'
      };
    }
  }

  // POST: Create Order
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          // You would typically include an auth token here
          // 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderData),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create order (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print("Error creating order: $e");
      throw Exception('Failed to create order: $e');
    }
  }

  // Get user addresses
  static Future<List<Address>> getUserAddresses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/addresses'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Address.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load addresses (${response.statusCode})');
      }
    } catch (e) {
      print("Error fetching addresses: $e");
      return []; // Return empty list rather than throwing to avoid crashes
    }
  }

  // Add user address with location data
  static Future<Map<String, dynamic>> addUserAddress(Map<String, dynamic> addressData) async {
    try {
      print("Adding address with data: $addressData");
      final response = await http.post(
        Uri.parse('$baseUrl/user/addresses'),
        headers: _headers,
        body: jsonEncode(addressData),
      );
      
      print("Address response status: ${response.statusCode}");
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add address (${response.statusCode})');
      }
    } catch (e) {
      print("Error adding address: $e");
      
      // Return mock response for testing
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Connection refused')) {
        return {
          'id': 'mock_address_id',
          ...addressData,
        };
      }
      
      rethrow;
    }
  }

  // Sample data for testing when API is unavailable
  static List<Restaurant> _getSampleRestaurants() {
    return [
      Restaurant(
        id: '1',
        name: 'Burger King',
        cuisine: 'Fast Food, Burger',
        imageUrl: 'https://via.placeholder.com/400x300?text=Burger+King',
        rating: 4.2,
        deliveryTime: 30,
        distance: 2.5,
        costForTwo: 350,
      ),
      Restaurant(
        id: '2',
        name: 'Pizza Hut',
        cuisine: 'Italian, Pizza',
        imageUrl: 'https://via.placeholder.com/400x300?text=Pizza+Hut',
        rating: 4.5,
        deliveryTime: 40,
        distance: 3.2,
        costForTwo: 500,
      ),
      // Add more sample restaurants if needed
    ];
  }
  
  // Sample menu data for testing
  static List<MenuItem> _getSampleMenuItems(String restaurantId) {
    return [
      MenuItem(
        id: '${restaurantId}_item1',
        name: 'Butter Chicken',
        description: 'Creamy tomato sauce with tender chicken pieces',
        price: 280.0,
        isVeg: false,
        imageUrl: 'https://via.placeholder.com/150?text=Butter+Chicken',
        categoryId: 'main_course',
      ),
      MenuItem(
        id: '${restaurantId}_item2',
        name: 'Paneer Tikka',
        description: 'Grilled cottage cheese with spices',
        price: 220.0,
        isVeg: true,
        imageUrl: 'https://via.placeholder.com/150?text=Paneer+Tikka',
        categoryId: 'starters',
      ),
      MenuItem(
        id: '${restaurantId}_item3',
        name: 'Veg Biryani',
        description: 'Fragrant rice with mixed vegetables',
        price: 180.0,
        isVeg: true,
        imageUrl: 'https://via.placeholder.com/150?text=Veg+Biryani',
        categoryId: 'rice',
      ),
      MenuItem(
        id: '${restaurantId}_item4',
        name: 'Gulab Jamun',
        description: 'Sweet milk solids dumplings',
        price: 120.0,
        isVeg: true,
        imageUrl: 'https://via.placeholder.com/150?text=Gulab+Jamun',
        categoryId: 'desserts',
      ),
    ];
  }
}

// Helper function to avoid error with min function
int min(int a, int b) => a < b ? a : b;
