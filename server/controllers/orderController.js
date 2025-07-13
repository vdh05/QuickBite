const { Order } = require('../models');

// Create a new order
exports.createOrder = async (req, res) => {
  try {
    const order = new Order(req.body);
    const newOrder = await order.save();
    res.status(201).json(newOrder);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Get user's orders
exports.getUserOrders = async (req, res) => {
  try {
    const userOrders = await Order.find({ userId: req.params.userId });
    res.json(userOrders);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
