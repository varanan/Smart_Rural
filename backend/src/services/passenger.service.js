const Passenger = require('../models/passenger.model');
const { signAccessToken, signRefreshToken } = require('../utils/jwt');
const logger = require('../utils/logger');

// Function to clean up any problematic database constraints
const cleanupPassengerCollection = async () => {
  try {
    // Remove any nicNumber field from existing passenger documents
    await Passenger.updateMany({}, { $unset: { nicNumber: 1 } });
    logger.info('Cleaned up passenger collection - removed nicNumber field');
  } catch (error) {
    logger.error('Error cleaning up passenger collection:', error.message);
  }
};

const createPassenger = async (input) => {
  try {
    // Clean up collection first (only run once)
    await cleanupPassengerCollection();
    
    // Explicitly filter only the allowed fields for passenger
    const allowedFields = {
      fullName: input.fullName,
      email: input.email,
      password: input.password,
      role: 'passenger',
      isActive: true
    };

    // Only add phone if it's provided and not empty
    if (input.phone && input.phone.trim() !== '') {
      allowedFields.phone = input.phone.trim();
    }

    // Log the fields being used for debugging
    console.log('Creating passenger with fields:', Object.keys(allowedFields));
    console.log('Input received:', input);
    
    const passenger = new Passenger(allowedFields);
    await passenger.save();
    
    const tokens = {
      access: signAccessToken({ id: passenger._id, role: passenger.role }),
      refresh: signRefreshToken({ id: passenger._id, role: passenger.role })
    };

    logger.info('Passenger created successfully', { passengerId: passenger._id, email: passenger.email });
    
    return {
      passenger: passenger.toJSON(),
      tokens
    };
  } catch (error) {
    logger.error('Error creating passenger', { error: error.message, input });
    
    // If it's still a duplicate key error, try to handle it
    if (error.code === 11000) {
      const field = Object.keys(error.keyValue)[0];
      if (field === 'nicNumber') {
        // Try to clean up and retry once
        await cleanupPassengerCollection();
        throw new Error('Database constraint issue resolved. Please try registration again.');
      }
    }
    
    throw error;
  }
};

const loginPassenger = async ({ email, password }) => {
  try {
    const passenger = await Passenger.findOne({ email, isActive: true });
    if (!passenger) {
      throw new Error('Invalid email or password');
    }

    const isPasswordValid = await passenger.comparePassword(password);
    if (!isPasswordValid) {
      throw new Error('Invalid email or password');
    }

    const tokens = {
      access: signAccessToken({ id: passenger._id, role: passenger.role }),
      refresh: signRefreshToken({ id: passenger._id, role: passenger.role })
    };

    logger.info('Passenger logged in successfully', { passengerId: passenger._id, email: passenger.email });
    
    return {
      passenger: passenger.toJSON(),
      tokens
    };
  } catch (error) {
    logger.error('Error during passenger login', { error: error.message, email });
    throw error;
  }
};

module.exports = {
  createPassenger,
  loginPassenger
};
