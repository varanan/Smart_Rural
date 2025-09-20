const Driver = require('../models/driver.model');
const { signAccessToken, signRefreshToken } = require('../utils/jwt');
const logger = require('../utils/logger');

const createDriver = async (input) => {
  try {
    const driver = new Driver(input);
    await driver.save();
    
    const tokens = {
      access: signAccessToken({ id: driver._id, role: driver.role }),
      refresh: signRefreshToken({ id: driver._id, role: driver.role })
    };

    logger.info('Driver created successfully', { driverId: driver._id, email: driver.email });
    
    return {
      driver: driver.toJSON(),
      tokens
    };
  } catch (error) {
    logger.error('Error creating driver', { error: error.message });
    throw error;
  }
};

const loginDriver = async ({ email, password }) => {
  try {
    const driver = await Driver.findOne({ email, isActive: true });
    if (!driver) {
      throw new Error('Invalid email or password');
    }

    const isPasswordValid = await driver.comparePassword(password);
    if (!isPasswordValid) {
      throw new Error('Invalid email or password');
    }

    const tokens = {
      access: signAccessToken({ id: driver._id, role: driver.role }),
      refresh: signRefreshToken({ id: driver._id, role: driver.role })
    };

    logger.info('Driver logged in successfully', { driverId: driver._id, email: driver.email });
    
    return {
      driver: driver.toJSON(),
      tokens
    };
  } catch (error) {
    logger.error('Error during driver login', { error: error.message, email });
    throw error;
  }
};

module.exports = {
  createDriver,
  loginDriver
};
