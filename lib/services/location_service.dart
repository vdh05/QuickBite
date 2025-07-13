import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/address.dart';

class LocationService {
  static final Location _location = Location();
  static const String _apiKey = 'AIzaSyC8_U4Jy9Gda99Du3eRaJOPwRhGh-ms4m4';
  
  // Request location permission and service
  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    // Check if permission is granted
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  // Get current location
  static Future<LocationData?> getCurrentLocation() async {
    try {
      if (await requestLocationPermission()) {
        return await _location.getLocation();
      }
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Enhanced method to get detailed address from coordinates
  static Future<Address?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // First attempt with Google Maps Geocoding API for more detailed results
      final String url = 
        'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=$latitude,$longitude'
        '&key=$_apiKey';
        
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Get the most detailed result
          final results = data['results'][0];
          final formattedAddress = results['formatted_address'];
          
          // Extract address components
          final components = results['address_components'];
          String street = '';
          String locality = '';
          String subLocality = '';
          String city = '';
          String state = '';
          String postalCode = '';
          
          for (var component in components) {
            final List<dynamic> types = component['types'];
            
            if (types.contains('route')) {
              street = component['long_name'];
            } else if (types.contains('sublocality_level_1')) {
              subLocality = component['long_name'];
            } else if (types.contains('locality')) {
              city = component['long_name'];
            } else if (types.contains('administrative_area_level_1')) {
              state = component['long_name'];
            } else if (types.contains('postal_code')) {
              postalCode = component['long_name'];
            } else if (types.contains('neighborhood') || types.contains('sublocality_level_2')) {
              locality = component['long_name'];
            }
          }
          
          // Construct a detailed address line
          String addressLine = '';
          if (street.isNotEmpty) addressLine += '$street, ';
          if (locality.isNotEmpty) addressLine += '$locality, ';
          if (subLocality.isNotEmpty) addressLine += '$subLocality, ';
          if (addressLine.isEmpty) addressLine = formattedAddress;
          
          // Trim trailing comma and space if present
          if (addressLine.endsWith(', ')) {
            addressLine = addressLine.substring(0, addressLine.length - 2);
          }
          
          return Address(
            id: '',
            addressLine: addressLine,
            city: city,
            state: state,
            zipCode: postalCode,
            landmark: locality.isNotEmpty ? locality : subLocality,
            addressType: 'Home',
            latitude: latitude,
            longitude: longitude,
            isDefault: true,
          );
        }
      }
      
      // Fallback to Flutter geocoding package if Google API fails
      final placemarks = await geo.placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Construct a more meaningful address
        String addressLine = '';
        if (place.street != null && place.street!.isNotEmpty) 
          addressLine += '${place.street}, ';
        if (place.subLocality != null && place.subLocality!.isNotEmpty) 
          addressLine += '${place.subLocality}, ';
        if (place.locality != null && place.locality!.isNotEmpty) 
          addressLine += '${place.locality}';
          
        // Trim trailing comma and space if present
        if (addressLine.endsWith(', ')) {
          addressLine = addressLine.substring(0, addressLine.length - 2);
        }
        
        if (addressLine.isEmpty) {
          // If all components are empty, use a combination of what's available
          addressLine = [
            place.street, 
            place.subLocality, 
            place.locality, 
            place.subAdministrativeArea
          ].where((element) => element != null && element.isNotEmpty).join(', ');
        }
        
        return Address(
          id: '',
          addressLine: addressLine,
          city: place.locality ?? '',
          state: place.administrativeArea ?? '',
          zipCode: place.postalCode ?? '',
          landmark: place.subLocality ?? '',
          addressType: 'Home',
          latitude: latitude,
          longitude: longitude,
          isDefault: true,
        );
      }
      return null;
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }
}
