import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapsService {
  static const String _apiKey = 'AIzaSyC8_U4Jy9Gda99Du3eRaJOPwRhGh-ms4m4';
  
  // Get directions between two locations
  static Future<Map<String, dynamic>?> getDirections(
    LatLng origin, 
    LatLng destination
  ) async {
    final String url = 
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&key=$_apiKey';
      
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }
  
  // Get polyline points for drawing route on map
  static Future<List<LatLng>> getPolylinePoints(
    LatLng origin, 
    LatLng destination
  ) async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    
    try {
      final directionsData = await getDirections(origin, destination);
      
      if (directionsData != null) {
        final routes = directionsData['routes'];
        
        if (routes.isNotEmpty) {
          final points = routes[0]['overview_polyline']['points'];
          final result = polylinePoints.decodePolyline(points);
          
          for (var point in result) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }
      }
      
      return polylineCoordinates;
    } catch (e) {
      print('Error getting polyline points: $e');
      return [];
    }
  }
  
  // Search for places using Google Places API
  static Future<List<dynamic>> searchPlaces(String query) async {
    final String url = 
      'https://maps.googleapis.com/maps/api/place/textsearch/json?'
      'query=$query&key=$_apiKey';
      
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['results'];
      }
      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }
  
  // Get human-readable address from latitude and longitude using Google Maps Geocoding API
  static Future<Map<String, dynamic>> getAddressFromLatLng(double latitude, double longitude) async {
    final String url = 
      'https://maps.googleapis.com/maps/api/geocode/json?'
      'latlng=$latitude,$longitude'
      '&key=$_apiKey';
      
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final results = data['results'][0];
          final formattedAddress = results['formatted_address'];
          
          // Extract address components
          final components = results['address_components'];
          Map<String, String> addressComponents = {};
          
          for (var component in components) {
            final List<dynamic> types = component['types'];
            
            if (types.contains('street_number')) {
              addressComponents['street_number'] = component['long_name'];
            } else if (types.contains('route')) {
              addressComponents['street'] = component['long_name'];
            } else if (types.contains('locality')) {
              addressComponents['city'] = component['long_name'];
            } else if (types.contains('administrative_area_level_1')) {
              addressComponents['state'] = component['long_name'];
            } else if (types.contains('country')) {
              addressComponents['country'] = component['long_name'];
            } else if (types.contains('postal_code')) {
              addressComponents['postal_code'] = component['long_name'];
            } else if (types.contains('sublocality_level_1')) {
              addressComponents['neighborhood'] = component['long_name'];
            }
          }
          
          return {
            'success': true,
            'formatted_address': formattedAddress,
            'components': addressComponents,
            'latitude': latitude,
            'longitude': longitude
          };
        } else {
          print('Geocoding error: ${data['status']}');
          return {
            'success': false,
            'error': 'No address found for this location',
            'status': data['status']
          };
        }
      } else {
        print('Geocoding API error: ${response.statusCode}');
        return {
          'success': false,
          'error': 'API request failed with status: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
  
  // Debug utility to check network connectivity and API access
  static Future<bool> testApiConnectivity() async {
    try {
      final testUrl = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&key=$_apiKey';
      final response = await http.get(Uri.parse(testUrl));
      
      if (response.statusCode == 200) {
        print('Google API Connection: SUCCESS');
        print('Response: ${response.body.substring(0, 100)}...');
        return true;
      } else {
        print('Google API Connection: FAILED');
        print('Status Code: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Network Error: $e');
      return false;
    }
  }
}
