import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart'; // Add this import for LocationData
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import '../models/address.dart';
import 'home_page.dart';

class AddressSetupScreen extends StatefulWidget {
  const AddressSetupScreen({Key? key}) : super(key: key);

  @override
  State<AddressSetupScreen> createState() => _AddressSetupScreenState();
}

class _AddressSetupScreenState extends State<AddressSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  String _addressType = 'Home';
  bool _isLoading = false;
  bool _isLoadingLocation = true;
  
  // Map controller
  GoogleMapController? _mapController;
  
  // Default camera position (will be updated with user's location)
  CameraPosition _cameraPosition = const CameraPosition(
    target: LatLng(20.5937, 78.9629), // Default to India
    zoom: 15,
  );
  
  // Current marker
  Set<Marker> _markers = {};
  
  // Current location data
  LocationData? _currentLocation;
  
  // Error message for address saving
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _landmarkController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Get current location and update map
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      final locationData = await LocationService.getCurrentLocation();
      
      if (locationData != null && locationData.latitude != null && locationData.longitude != null) {
        // Update camera position
        final newPosition = CameraPosition(
          target: LatLng(locationData.latitude!, locationData.longitude!),
          zoom: 16,
        );
        
        setState(() {
          _cameraPosition = newPosition;
          _markers = {
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(locationData.latitude!, locationData.longitude!),
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          };
        });
        
        // Update map camera
        _mapController?.animateCamera(CameraUpdate.newCameraPosition(newPosition));
        
        // Get address from coordinates
        await _getAddressFromLocation(locationData.latitude!, locationData.longitude!);
        
        // Save current location
        setState(() {
          _currentLocation = locationData;
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Get address details from latitude and longitude
  Future<void> _getAddressFromLocation(double latitude, double longitude) async {
    try {
      final address = await LocationService.getAddressFromCoordinates(latitude, longitude);
      
      if (address != null) {
        // Update text fields with address details
        setState(() {
          _addressLineController.text = address.addressLine;
          _cityController.text = address.city;
          _stateController.text = address.state;
          _zipCodeController.text = address.zipCode;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  // Update marker when map is tapped
  void _onMapTapped(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selectedLocation'),
          position: position,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      };
    });
    
    // Get address from tapped position
    _getAddressFromLocation(position.latitude, position.longitude);
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get the current location if not already fetched
      if (_currentLocation == null) {
        await _getCurrentLocation();
      }
      
      if (_currentLocation == null) {
        // Show error message if location couldn't be fetched
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to get your location. Please try again.';
        });
        return;
      }
      
      // Prepare address data
      final addressData = {
        'addressLine': _addressLineController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zipCode': _zipCodeController.text,
        'landmark': _landmarkController.text,
        'addressType': _addressType,
        'latitude': _currentLocation!.latitude,
        'longitude': _currentLocation!.longitude,
        'isDefault': true,
      };
      
      // Save address through AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.saveUserAddress(addressData);
      
      if (!mounted) return;
      
      if (success) {
        // Navigate to home page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const HomePage()),
          (route) => false,
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to save address. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
      print('Error saving address: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Delivery Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map view
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      // Google Map
                      GoogleMap(
                        initialCameraPosition: _cameraPosition,
                        markers: _markers,
                        onMapCreated: (controller) => _mapController = controller,
                        onTap: _onMapTapped,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                      
                      // Loading indicator
                      if (_isLoadingLocation)
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      
                      // Recenter button
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: _getCurrentLocation,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Address form fields
              TextFormField(
                controller: _addressLineController,
                decoration: const InputDecoration(
                  labelText: 'Address Line',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // City and State in a row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter city';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter state';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _zipCodeController,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.markunread_mailbox),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter ZIP code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(
                  labelText: 'Landmark (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.landscape),
                ),
              ),
              const SizedBox(height: 16),
              
              // Address Type
              const Text(
                'Address Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildAddressTypeChip('Home', Icons.home),
                  const SizedBox(width: 16),
                  _buildAddressTypeChip('Work', Icons.work),
                  const SizedBox(width: 16),
                  _buildAddressTypeChip('Other', Icons.place),
                ],
              ),
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Text(
                          'CONFIRM LOCATION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressTypeChip(String type, IconData icon) {
    final isSelected = _addressType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _addressType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 4),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
