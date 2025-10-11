const Driver = require('../models/driver.model');
const { signAccessToken, signRefreshToken } = require('../utils/jwt');
const logger = require('../utils/logger');

const createDriver = async (input) => {
  try {
    // Check if a rejected driver exists with this email
    const existingDriver = await Driver.findOne({ 
      email: input.email.toLowerCase().trim() 
    });

    if (existingDriver) {
      // Only allow re-registration if the driver was rejected
      if (existingDriver.verificationStatus === 'rejected') {
        logger.info('Rejected driver re-registering, deleting old account', { 
          oldDriverId: existingDriver._id, 
          email: existingDriver.email 
        });
        
        // Delete the old rejected account
        await Driver.findByIdAndDelete(existingDriver._id);
        
        logger.info('Old rejected driver account deleted successfully', {
          email: existingDriver.email
        });
      } else {
        // Driver exists and is not rejected (pending or approved)
        throw new Error('A driver with this email already exists');
      }
    }

    // Check for duplicate license number
    const existingLicense = await Driver.findOne({ 
      licenseNumber: input.licenseNumber.toUpperCase().trim() 
    });
    
    if (existingLicense) {
      if (existingLicense.verificationStatus === 'rejected') {
        await Driver.findByIdAndDelete(existingLicense._id);
        logger.info('Deleted rejected driver with same license number', {
          licenseNumber: input.licenseNumber
        });
      } else {
        throw new Error('A driver with this license number already exists');
      }
    }

    // Check for duplicate NIC number
    const existingNIC = await Driver.findOne({ 
      nicNumber: input.nicNumber.toUpperCase().trim() 
    });
    
    if (existingNIC) {
      if (existingNIC.verificationStatus === 'rejected') {
        await Driver.findByIdAndDelete(existingNIC._id);
        logger.info('Deleted rejected driver with same NIC number', {
          nicNumber: input.nicNumber
        });
      } else {
        throw new Error('A driver with this NIC number already exists');
      }
    }

    // Create new driver account
    const driver = new Driver(input);
    await driver.save();
    
    const tokens = {
      access: signAccessToken({ id: driver._id, role: driver.role }),
      refresh: signRefreshToken({ id: driver._id, role: driver.role })
    };

    logger.info('Driver created successfully', { 
      driverId: driver._id, 
      email: driver.email 
    });
    
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

    logger.info('Driver logged in successfully', { 
      driverId: driver._id, 
      email: driver.email 
    });
    
    return {
      driver: driver.toJSON(),
      tokens
    };
  } catch (error) {
    logger.error('Error during driver login', { 
      error: error.message, 
      email 
    });
    throw error;
  }
};

module.exports = {
  createDriver,
  loginDriver
};
