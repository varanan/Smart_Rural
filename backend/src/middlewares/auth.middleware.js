const { verifyAccessToken } = require('../utils/jwt');
const Driver = require('../models/driver.model');
const logger = require('../utils/logger');

const requireAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access token required'
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    const decoded = verifyAccessToken(token);
    
    const driver = await Driver.findById(decoded.id).select('-password');
    if (!driver || !driver.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Driver not found or inactive'
      });
    }

    req.driver = driver;
    next();
  } catch (error) {
    logger.error('Authentication failed', { error: error.message });
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token'
    });
  }
};

module.exports = { requireAuth };