const { verifyAccessToken } = require('../utils/jwt');
const Admin = require('../models/admin.model');
const Driver = require('../models/driver.model');
const Passenger = require('../models/passenger.model');
const Connector = require('../models/connector.model');
const logger = require('../utils/logger');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access token is required'
      });
    }

    const token = authHeader.substring(7);
    const decoded = verifyAccessToken(token);

    // Find user based on role
    let user;
    if (decoded.role === 'admin' || decoded.role === 'super_admin') {
      user = await Admin.findById(decoded.id).select('-password');
    } else if (decoded.role === 'driver') {
      user = await Driver.findById(decoded.id).select('-password');
    } else if (decoded.role === 'passenger') {
      user = await Passenger.findById(decoded.id).select('-password');
    } else if (decoded.role === 'connector') {
      user = await Connector.findById(decoded.id).select('-password');
    }

    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'User not found or inactive'
      });
    }

    req.user = user;
    next();
  } catch (error) {
    logger.error('Authentication failed', { error: error.message });
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token'
    });
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions'
      });
    }

    next();
  };
};

// Add this new middleware function after the authorize function
const requireVerification = (req, res, next) => {
  // Only check verification for drivers
  if (req.user.role === 'driver') {
    if (!req.user.isVerified || req.user.verificationStatus !== 'approved') {
      return res.status(403).json({
        success: false,
        message: 'Your account must be verified by admin before performing this action',
        verificationStatus: req.user.verificationStatus,
        rejectionReason: req.user.rejectionReason
      });
    }
  }
  next();
};

module.exports = {
  authenticate,
  authorize,
  requireVerification  // Export the new middleware
};