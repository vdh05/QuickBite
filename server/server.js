const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const mongoose = require('mongoose');
require('dotenv').config();

// Import controllers
const { 
  restaurantController, 
  orderController, 
  userController 
} = require('./controllers');

// Initialize express app
const app = express();
const PORT = process.env.PORT || 5000;

// MongoDB Connection URI from environment variables
const MONGODB_URI = process.env.MONGODB_URI;

// Connect to MongoDB
mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('MongoDB connected successfully'))
.catch(err => console.error('MongoDB connection error:', err));

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Root route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Food Delivery API' });
});

// Restaurant routes
app.get('/api/restaurants', restaurantController.getAllRestaurants);
app.get('/api/restaurants/:id', restaurantController.getRestaurantById);
app.post('/api/restaurants', restaurantController.createRestaurant);
app.get('/api/restaurants/:id/menu', restaurantController.getRestaurantMenu);
app.post('/api/restaurants/:id/menu', restaurantController.addMenuItem);
app.post('/api/restaurants/:id/like', restaurantController.likeRestaurant);
app.post('/api/restaurants/:id/unlike', restaurantController.unlikeRestaurant);
app.get('/api/users/:userId/liked-restaurants', restaurantController.getLikedRestaurants);

// Order routes
app.post('/api/orders', orderController.createOrder);
app.get('/api/users/:userId/orders', orderController.getUserOrders);

// User routes
app.post('/api/auth/register', userController.register);
app.post('/api/auth/login', userController.login);

// Start the server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
