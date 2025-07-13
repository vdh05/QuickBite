const { Restaurant, MenuItem } = require('../models');

// Get all restaurants
exports.getAllRestaurants = async (req, res) => {
  try {
    const restaurants = await Restaurant.find();
    res.json(restaurants);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get a specific restaurant
exports.getRestaurantById = async (req, res) => {
  try {
    const restaurant = await Restaurant.findById(req.params.id);
    if (!restaurant) return res.status(404).json({ message: 'Restaurant not found' });
    res.json(restaurant);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Create a new restaurant
exports.createRestaurant = async (req, res) => {
  try {
    const restaurant = new Restaurant(req.body);
    const newRestaurant = await restaurant.save();
    res.status(201).json(newRestaurant);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Get menu items for a restaurant
exports.getRestaurantMenu = async (req, res) => {
  try {
    const items = await MenuItem.find({ restaurantId: req.params.id });
    res.json(items);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Add a menu item to a restaurant
exports.addMenuItem = async (req, res) => {
  try {
    const menuItem = new MenuItem({
      ...req.body,
      restaurantId: req.params.id
    });
    const newMenuItem = await menuItem.save();
    res.status(201).json(newMenuItem);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Like a restaurant
exports.likeRestaurant = async (req, res) => {
  try {
    const { userId } = req.body;
    const restaurantId = req.params.id;
    
    // Validate inputs
    if (!userId || !restaurantId) {
      return res.status(400).json({ message: 'User ID and restaurant ID are required' });
    }
    
    // Find the restaurant and user
    const restaurant = await Restaurant.findById(restaurantId);
    const user = await User.findById(userId);
    
    if (!restaurant) {
      return res.status(404).json({ message: 'Restaurant not found' });
    }
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Check if user already liked this restaurant
    const alreadyLiked = restaurant.likes.includes(userId);
    
    if (alreadyLiked) {
      return res.status(400).json({ message: 'Restaurant already liked by this user' });
    }
    
    // Add user to restaurant's likes
    restaurant.likes.push(userId);
    restaurant.likesCount = restaurant.likes.length;
    await restaurant.save();
    
    // Add restaurant to user's likedRestaurants
    user.likedRestaurants.push(restaurantId);
    await user.save();
    
    res.status(200).json({ message: 'Restaurant liked successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Unlike a restaurant
exports.unlikeRestaurant = async (req, res) => {
  try {
    const { userId } = req.body;
    const restaurantId = req.params.id;
    
    // Validate inputs
    if (!userId || !restaurantId) {
      return res.status(400).json({ message: 'User ID and restaurant ID are required' });
    }
    
    // Find the restaurant and user
    const restaurant = await Restaurant.findById(restaurantId);
    const user = await User.findById(userId);
    
    if (!restaurant) {
      return res.status(404).json({ message: 'Restaurant not found' });
    }
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Check if user liked this restaurant
    const likedIndex = restaurant.likes.indexOf(userId);
    
    if (likedIndex === -1) {
      return res.status(400).json({ message: 'Restaurant not liked by this user' });
    }
    
    // Remove user from restaurant's likes
    restaurant.likes.splice(likedIndex, 1);
    restaurant.likesCount = restaurant.likes.length;
    await restaurant.save();
    
    // Remove restaurant from user's likedRestaurants
    const restaurantIndex = user.likedRestaurants.indexOf(restaurantId);
    if (restaurantIndex !== -1) {
      user.likedRestaurants.splice(restaurantIndex, 1);
      await user.save();
    }
    
    res.status(200).json({ message: 'Restaurant unliked successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get all restaurants liked by a user
exports.getLikedRestaurants = async (req, res) => {
  try {
    const userId = req.params.userId;
    
    const user = await User.findById(userId).populate('likedRestaurants');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(user.likedRestaurants);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
