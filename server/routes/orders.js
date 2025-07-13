const express = require('express');
const router = express.Router();
const { Order, Restaurant, MenuItem } = require('../models');
const auth = require('../middleware/auth');

// POST /api/orders - Create a new order
router.post('/', auth, async (req, res) => {
  try {
    const {
      restaurantId,
      items,
      deliveryAddress,
      paymentMethod,
      specialInstructions,
    } = req.body;

    // Validate restaurant
    const restaurant = await Restaurant.findById(restaurantId);
    if (!restaurant) {
      return res.status(404).json({ message: 'Restaurant not found' });
    }

    // Calculate order total
    let totalAmount = 0;
    const orderItems = [];

    for (const item of items) {
      const menuItem = await MenuItem.findById(item.menuItemId);
      if (!menuItem) {
        return res.status(404).json({ message: `Menu item ${item.menuItemId} not found` });
      }

      const itemTotal = menuItem.price * item.quantity;
      totalAmount += itemTotal;

      orderItems.push({
        menuItem: menuItem._id,
        name: menuItem.name,
        price: menuItem.price,
        quantity: item.quantity,
        totalPrice: itemTotal,
      });
    }

    // Add delivery fee
    const deliveryFee = 40; // Default delivery fee
    totalAmount += deliveryFee;

    // Create order
    const order = new Order({
      user: req.userId,
      restaurant: restaurantId,
      items: orderItems,
      deliveryAddress,
      paymentMethod,
      specialInstructions,
      totalAmount,
      deliveryFee,
      status: 'pending',
    });

    await order.save();

    res.status(201).json({
      message: 'Order created successfully',
      order: {
        id: order._id,
        restaurantName: restaurant.name,
        items: orderItems,
        totalAmount,
        status: order.status,
        createdAt: order.createdAt,
      },
    });
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// GET /api/orders - Get all orders for the current user
router.get('/', auth, async (req, res) => {
  try {
    const orders = await Order.find({ user: req.userId })
      .populate('restaurant', 'name imageUrl')
      .sort({ createdAt: -1 });

    res.json(orders);
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// GET /api/orders/:id - Get a specific order
router.get('/:id', auth, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('restaurant', 'name imageUrl address')
      .populate('user', 'name phone');

    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    // Check if the order belongs to the current user
    if (order.user._id.toString() !== req.userId) {
      return res.status(403).json({ message: 'Not authorized to view this order' });
    }

    res.json(order);
  } catch (error) {
    console.error('Error fetching order:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;
