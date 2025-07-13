const express = require('express');
const router = express.Router();
const { Restaurant, MenuItem } = require('../models');

// GET /api/restaurants - Get all restaurants
router.get('/', async (req, res) => {
  try {
    const restaurants = await Restaurant.find();
    res.json(restaurants);
  } catch (error) {
    console.error('Error fetching restaurants:', error);
    res.status(500).json({ message: 'Failed to fetch restaurants', error: error.message });
  }
});

// GET /api/restaurants/:id - Get a specific restaurant
router.get('/:id', async (req, res) => {
  try {
    const restaurant = await Restaurant.findById(req.params.id);
    if (!restaurant) {
      return res.status(404).json({ message: 'Restaurant not found' });
    }
    res.json(restaurant);
  } catch (error) {
    console.error('Error fetching restaurant:', error);
    res.status(500).json({ message: 'Failed to fetch restaurant', error: error.message });
  }
});

// GET /api/restaurants/:id/menu - Get menu items for a specific restaurant
router.get('/:id/menu', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Fetch menu items from the database
    const menuItems = await MenuItem.find({ restaurantId: id });
    
    res.json(menuItems);
  } catch (error) {
    console.error('Error fetching menu items:', error);
    res.status(500).json({ message: 'Failed to fetch menu items', error: error.message });
  }
});

module.exports = router;
