const { verifyRefreshToken, signAccessToken } = require('../utils/jwt');
const Driver = require('../models/driver.model');
const logger = require('../utils/logger');

const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    const decoded = verifyRefreshToken(refreshToken);
    
    const driver = await Driver.findById(decoded.id).select('-password');
    if (!driver || !driver.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Driver not found or inactive'
      });
    }

    const accessToken = signAccessToken({ id: driver._id, role: driver.role });
    
    logger.info('Token refreshed successfully', { driverId: driver._id });
    
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
