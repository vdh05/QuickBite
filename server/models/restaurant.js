const mongoose = require('mongoose');

const restaurantSchema = new mongoose.Schema({
  name: { type: String, required: true },
  cuisine: { type: String, required: true },
  imageUrl: { type: String, required: true },
  rating: { type: Number, default: 0 },
  deliveryTime: { type: Number, required: true },
  distance: { type: Number, required: true },
  
  // Simple price range indicator using Rupee symbols
  priceRange: { 
    type: String, 
    enum: ['₹', '₹₹', '₹₹₹', '₹₹₹₹'],
    default: '₹₹',
    description: {
      '₹': 'Budget (Under ₹300)',
      '₹₹': 'Moderate (₹300-₹600)',
      '₹₹₹': 'Premium (₹600-₹1000)',
      '₹₹₹₹': 'Luxury (Above ₹1000)'
    }
  },
  
  // Specific average cost for two people
  costForTwo: { 
    type: Number, 
    required: false 
  },
  
  // Add likes field to track users who liked this restaurant
});

module.exports = mongoose.model('Restaurant', restaurantSchema);
