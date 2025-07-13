import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;
    final userData = authProvider.userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
      ),
      body: isLoggedIn ? _buildLoggedInView(context, userData, authProvider) : _buildLoginPrompt(context),
    );
  }

  Widget _buildLoggedInView(BuildContext context, Map<String, dynamic>? userData, AuthProvider authProvider) {
    // Enhanced debugging information
    print("User data in account page: $userData");
    print("UserName from provider: ${authProvider.userName}");
    print("UserProfile from provider: ${authProvider.userProfile}");
    
    // Get user data with enhanced priority order
    String name = '';
    
    // First try authProvider's direct properties which may be more up-to-date
    if (authProvider.userName != null && authProvider.userName!.isNotEmpty) {
      name = authProvider.userName!;
    }
    // Then try from userData map
    else if (userData != null && userData.containsKey('name') && userData['name'] != null) {
      name = userData['name'].toString();
    }
    // Try nested user object
    else if (userData != null && userData.containsKey('user') && 
             userData['user'] is Map && (userData['user'] as Map).containsKey('name')) {
      name = userData['user']['name'].toString();
    }
    // Try userProfile as last resort
    else if (authProvider.userProfile != null && 
             authProvider.userProfile!.containsKey('name') && 
             authProvider.userProfile!['name'] != null) {
      name = authProvider.userProfile!['name'].toString();
    }
    // Default if all else fails
    else {
      name = 'User';
    }
    
    // Sanitize name to prevent any display issues
    name = name.trim();
    if (name.isEmpty) name = 'User';
    
    final String email = _getUserDataField(userData, 'email');
    final String phone = _getUserDataField(userData, 'phone');
    
    // Get user initials for avatar
    final String initials = name.isNotEmpty 
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join().substring(0, name.split(' ').length > 1 ? 2 : 1)
        : 'U';

    // Get address info
    final hasAddress = authProvider.hasSetupAddress;
    final addresses = authProvider.addresses;
    final defaultAddress = hasAddress && addresses.isNotEmpty ? addresses[0] : null;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align to top for better layout
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded( // Wrap in Expanded to prevent overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis, // Prevent long emails from overflowing
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit profile')),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(),

        // Address Section
        if (defaultAddress != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      defaultAddress.addressType == 'Home' 
                          ? Icons.home 
                          : defaultAddress.addressType == 'Work'
                              ? Icons.work
                              : Icons.place,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${defaultAddress.addressType} Address',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  defaultAddress.addressLine,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  '${defaultAddress.city}, ${defaultAddress.state} ${defaultAddress.zipCode}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (defaultAddress.landmark.isNotEmpty)
                  Text(
                    'Landmark: ${defaultAddress.landmark}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          // Show add address option if no address exists
          ListTile(
            leading: Icon(Icons.add_location, color: Theme.of(context).primaryColor),
            title: const Text('Add a delivery address'),
            onTap: () {
              // Navigate to address setup screen
              Navigator.of(context).pushNamed('/address-setup');
            },
            tileColor: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Account Options
        _buildAccountOption(
          context,
          'My Orders',
          Icons.receipt_long,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('My Orders')),
            );
          },
        ),
        
        _buildAccountOption(
          context,
          'Addresses',
          Icons.location_on,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Addresses')),
            );
          },
        ),
        
        _buildAccountOption(
          context,
          'Payment Methods',
          Icons.payment,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment Methods')),
            );
          },
        ),
        
        _buildAccountOption(
          context,
          'Offers & Promos',
          Icons.local_offer,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Offers & Promos')),
            );
          },
        ),
        
        _buildAccountOption(
          context,
          'Favorites',
          Icons.favorite,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Favorites')),
            );
          },
        ),
        
        const Divider(),
        
        // Logout Button
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      authProvider.logout();
                      // Optionally navigate to login page
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (ctx) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    child: const Text('LOGOUT'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Not logged in',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please login to access your account',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'LOGIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Enhanced helper method to safely extract user data with more logging
  String _getUserDataField(Map<String, dynamic>? userData, String field) {
    if (userData == null) {
      print("userData is null when trying to extract $field");
      return field == 'name' ? 'User' : 'Not available';
    }
    
    // Try to get the field directly
    if (userData.containsKey(field) && userData[field] != null) {
      print("Found $field directly in userData: ${userData[field]}");
      return userData[field].toString();
    }
    
    // Try to get from nested 'user' object if present
    if (userData.containsKey('user') && 
        userData['user'] is Map && 
        (userData['user'] as Map).containsKey(field)) {
      print("Found $field in nested user object: ${userData['user'][field]}");
      return userData['user'][field].toString();
    }
    
    print("Could not find $field in userData");
    
    // Default values based on field type
    switch (field) {
      case 'name':
        return 'User';
      case 'email':
        return 'No email provided';
      case 'phone':
        return 'No phone provided';
      default:
        return 'Not available';
    }
  }
}
