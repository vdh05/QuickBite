import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailsPage({Key? key, required this.restaurant}) : super(key: key);

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  bool _isLoading = true;
  List<MenuItem> _menuItems = [];
  String? _errorMessage;
  MenuItem? _selectedMenuItem; // Track selected menu item for modal
  
  // Track liked menu items with a Set of item IDs
  final Set<String> _likedItems = {};
  
  // Menu categories for grouping
  final List<String> _categories = ['Recommended', 'Starters', 'Main Course', 'Desserts', 'Beverages'];
  
  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final menuItems = await ApiService.getMenuForRestaurant(widget.restaurant.id);
      
      setState(() {
        _menuItems = menuItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load menu: $e';
        _isLoading = false;
      });
    }
  }

  // Toggle like status for a menu item
  void _toggleLike(String menuItemId) {
    setState(() {
      if (_likedItems.contains(menuItemId)) {
        _likedItems.remove(menuItemId);
      } else {
        _likedItems.add(menuItemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildRestaurantInfo(),
              
              // Menu loading/error states
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchMenu,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_menuItems.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No menu items available')),
                )
              else
                _buildMenuList(),
            ],
          ),
          
          // Menu item detail modal - slides up from bottom
          if (_selectedMenuItem != null) _buildMenuItemDetailModal(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(widget.restaurant.name),
        background: Image.network(
          widget.restaurant.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.restaurant)),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.restaurant.cuisine,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 14),
                      Text(
                        widget.restaurant.rating.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.restaurant.deliveryTime} mins',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ₹${widget.restaurant.costForTwo} for two',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final category = _categories[index];
          final categoryItems = _menuItems.where(
            (item) => item.categoryId.toLowerCase().contains(category.toLowerCase()) ||
                      (category == 'Recommended' && index == 0) // Show some items as recommended
          ).toList();
          
          if (categoryItems.isEmpty) return const SizedBox.shrink();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: categoryItems.length,
                itemBuilder: (context, i) => _buildMenuItem(categoryItems[i]),
              ),
              const Divider(),
            ],
          );
        },
        childCount: _categories.length,
      ),
    );
  }

  Widget _buildMenuItem(MenuItem menuItem) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isLiked = _likedItems.contains(menuItem.id);
    
    return InkWell(
      onTap: () {
        // Show menu item detail modal when item is tapped
        setState(() {
          _selectedMenuItem = menuItem;
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: menuItem.isVeg ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Icon(
                            Icons.circle,
                            color: menuItem.isVeg ? Colors.green : Colors.red,
                            size: 8,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            menuItem.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Add like button
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => _toggleLike(menuItem.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${menuItem.price}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Item image and add button
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      menuItem.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      cartProvider.addItem(menuItem);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${menuItem.name} added to cart'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white, // Add this to ensure text is white
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Increase padding
                      minimumSize: const Size(80, 32),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold, // Make text bold for better visibility
                      ),
                    ),
                    child: const Text('ADD'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Menu item detail modal that slides up from bottom
  Widget _buildMenuItemDetailModal() {
    final menuItem = _selectedMenuItem!;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isLiked = _likedItems.contains(menuItem.id);
    
    return GestureDetector(
      // Close modal when tapping outside
      onTap: () {
        setState(() {
          _selectedMenuItem = null;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.6), // Dimmed background
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Modal content
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: MediaQuery.of(context).size.height * 0.6, // 60% of screen height
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal header with close button
                  Stack(
                    children: [
                      // Item image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          menuItem.imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.restaurant, size: 50)),
                          ),
                        ),
                      ),
                      // Close button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Row(
                          children: [
                            // Add like button
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 16,
                              child: IconButton(
                                icon: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.grey,
                                  size: 16,
                                ),
                                onPressed: () => _toggleLike(menuItem.id),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                color: Colors.black,
                                onPressed: () {
                                  setState(() {
                                    _selectedMenuItem = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Veg/Non-veg indicator
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: menuItem.isVeg ? Colors.green : Colors.red,
                                  ),
                                ),
                                child: Icon(
                                  Icons.circle,
                                  color: menuItem.isVeg ? Colors.green : Colors.red,
                                  size: 8,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                menuItem.isVeg ? 'Veg' : 'Non-Veg',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Item details
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menuItem.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${menuItem.price}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            menuItem.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Add to cart button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          cartProvider.addItem(menuItem);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${menuItem.name} added to cart'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                          setState(() {
                            _selectedMenuItem = null; // Close modal after adding
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white, // Add this to ensure text is white
                          padding: const EdgeInsets.symmetric(vertical: 16), // Increase padding
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5, // Add slight letter spacing for better readability
                          ),
                          elevation: 2, // Add slight elevation for better visibility
                        ),
                        child: const Text('ADD TO CART'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
