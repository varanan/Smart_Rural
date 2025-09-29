const Connector = require('../models/connector.model');
const { signAccessToken, signRefreshToken } = require('../utils/jwt');
const logger = require('../utils/logger');

const registerConnector = async (input) => {
  try {
    // ensure confirmPassword matches if provided
    if (input.confirmPassword && input.password !== input.confirmPassword) {
      const err = new Error('Passwords do not match');
      err.status = 400;
      throw err;
    }

    // Only keep expected fields
    const allowed = {
      fullName: input.fullName,
      email: input.email,
      password: input.password,
      phone: input.phone,
      licenseNumber: input.licenseNumber,
      nicNumber: input.nicNumber,
      vehicleNumber: input.vehicleNumber,
      role: 'connector',
      isActive: true
    };

    // Optional phone: remove if empty
    if (!allowed.phone || `${allowed.phone}`.trim() === '') delete allowed.phone;

    const connector = new Connector(allowed);
    await connector.save();

    const tokens = {
      access: signAccessToken({ id: connector._id, role: connector.role }),
      refresh: signRefreshToken({ id: connector._id, role: connector.role })
    };

    logger.info('Connector created successfully', { connectorId: connector._id, email: connector.email });

    return {
      connector: connector.toJSON(),
      tokens
    };
  } catch (error) {
    logger.error('Error creating connector', { error: error.message });
    throw error;
  }
};

const loginConnector = async ({ email, password }) => {
  try {
    const connector = await Connector.findOne({ email, isActive: true });
    if (!connector) {
      const err = new Error('Invalid email or password');
      err.status = 401;
      throw err;
    }

    const isValid = await connector.comparePassword(password);
    if (!isValid) {
      const err = new Error('Invalid email or password');
      err.status = 401;
      throw err;
    }

    const tokens = {
      access: signAccessToken({ id: connector._id, role: connector.role }),
      refresh: signRefreshToken({ id: connector._id, role: connector.role })
    };

    logger.info('Connector logged in successfully', { connectorId: connector._id, email: connector.email });

    return {
      connector: connector.toJSON(),
      tokens
    };
  } catch (error) {
    logger.error('Error during connector login', { error: error.message, email });
    throw error;
  }
};

module.exports = {
  registerConnector,
  loginConnector
};