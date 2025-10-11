const { verifyRefreshToken, signAccessToken } = require('../utils/jwt');
const Driver = require('../models/driver.model');
const Passenger = require('../models/passenger.model');
const Admin = require('../models/admin.model');
const logger = require('../utils/logger');

const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    const decoded = verifyRefreshToken(refreshToken);
    
    // Find user based on role
    let user;
    if (decoded.role === 'admin' || decoded.role === 'super_admin') {
      user = await Admin.findById(decoded.id).select('-password');
    } else if (decoded.role === 'driver') {
      user = await Driver.findById(decoded.id).select('-password');
    } else if (decoded.role === 'passenger') {
      user = await Passenger.findById(decoded.id).select('-password');
    }

    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'User not found or inactive'
      });
    }

    const accessToken = signAccessToken({ id: user._id, role: user.role });
    
    logger.info('Token refreshed successfully', { userId: user._id, role: user.role });
    
    res.json({
      success: true,
      data: {
        accessToken
      }
    });
  } catch (error) {
    logger.error('Token refresh failed', { error: error.message });
    next(error);
  }
};

module.exports = {
  refreshToken
};
