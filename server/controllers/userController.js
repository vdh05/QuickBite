const { User } = require('../models');

// User registration
exports.register = async (req, res) => {
  try {
    // Check if user already exists
    const existingUser = await User.findOne({ email: req.body.email });
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists with this email' });
    }
    
    // In a real app, you would hash the password before storing
    const user = new User(req.body);
    const newUser = await user.save();
    
    // Don't send password back in response
    const userResponse = newUser.toObject();
    delete userResponse.password;
    
    res.status(201).json(userResponse);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// User login
exports.login = async (req, res) => {
  try {
    const user = await User.findOne({ email: req.body.email });
    
    if (!user || user.password !== req.body.password) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    
    // In a real app, you would generate and return a JWT token here
    const userResponse = user.toObject();
    delete userResponse.password;
    
    res.json({
      user: userResponse,
      token: 'sample-jwt-token'
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
