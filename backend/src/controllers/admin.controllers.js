const bcrypt = require('bcryptjs');
const Admin = require('../models/admin.model');
const Driver = require('../models/driver.model');
const Connector = require('../models/connector.model');
const { signAccessToken, signRefreshToken } = require('../utils/jwt');
const logger = require('../utils/logger');

const register = async (req, res, next) => {
  try {
    const { name, email, password, phone } = req.body;

    // Normalize email to lowercase and trim
    const normalizedEmail = email.toLowerCase().trim();
    
    logger.info('Admin registration attempt', { 
      email: normalizedEmail,
      name: name?.trim() 
    });

    // Check if admin already exists with detailed logging
    const existingAdmin = await Admin.findOne({ email: normalizedEmail });
    if (existingAdmin) {
      logger.warn('Admin registration failed - email already exists', { 
        attemptedEmail: normalizedEmail,
        existingAdminId: existingAdmin._id,
        existingAdminName: existingAdmin.name
      });
      return res.status(400).json({
        success: false,
        message: 'Admin with this email already exists',
        debug: {
          attemptedEmail: normalizedEmail,
          existingAdmin: {
            id: existingAdmin._id,
            name: existingAdmin.name,
            email: existingAdmin.email
          }
        }
      });
    }

    // Create new admin with normalized email
    const adminData = { 
      name: name.trim(), 
      email: normalizedEmail, 
      password 
    };
    if (phone && phone.trim()) {
      adminData.phone = phone.trim();
    }

    logger.info('Creating new admin', { adminData: { ...adminData, password: '[HIDDEN]' } });

    const admin = new Admin(adminData);
    await admin.save();

    // Generate tokens
    const payload = { id: admin._id, role: admin.role };
    const accessToken = signAccessToken(payload);
    const refreshToken = signRefreshToken(payload);

    logger.info('Admin registered successfully', { 
      adminId: admin._id, 
      email: admin.email,
      name: admin.name
    });

    res.status(201).json({
      success: true,
      message: 'Admin registered successfully',
      data: {
        admin,
        accessToken,
        refreshToken
      }
    });
  } catch (error) {
    logger.error('Admin registration failed', { 
      error: error.message,
      code: error.code,
      name: error.name,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
    
    if (error.code === 11000) {
      // MongoDB duplicate key error
      const field = Object.keys(error.keyPattern || {})[0] || 'email';
      const value = error.keyValue ? error.keyValue[field] : 'unknown';
      
      logger.error('MongoDB duplicate key error', { 
        field, 
        value, 
        keyPattern: error.keyPattern,
        keyValue: error.keyValue 
      });
      
      return res.status(400).json({
        success: false,
        message: `Admin with this ${field} already exists`,
        debug: {
          duplicateField: field,
          duplicateValue: value,
          mongoError: error.code
        }
      });
    }
    
    // Handle validation errors
    if (error.name === 'ValidationError') {
      const errors = Object.values(error.errors).map(err => ({
        field: err.path,
        message: err.message,
        value: err.value
      }));
      
      logger.error('Validation error', { errors });
      
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors
      });
    }
    
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Normalize email to lowercase and trim
    const normalizedEmail = email.toLowerCase().trim();

    // Find admin by email
    const admin = await Admin.findOne({ email: normalizedEmail });
    if (!admin) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Check if admin is active
    if (!admin.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Admin account is deactivated'
      });
    }

    // Verify password
    const isPasswordValid = await admin.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Update last login
    admin.lastLogin = new Date();
    await admin.save();

    // Generate tokens
    const payload = { id: admin._id, role: admin.role };
    const accessToken = signAccessToken(payload);
    const refreshToken = signRefreshToken(payload);

    logger.info('Admin logged in successfully', { 
      adminId: admin._id, 
      email: admin.email 
    });

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        admin,
        accessToken,
        refreshToken
      }
    });
  } catch (error) {
    logger.error('Admin login failed', { error: error.message });
    next(error);
  }
};

const getProfile = async (req, res, next) => {
  try {
    const admin = await Admin.findById(req.user.id);
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found'
      });
    }

    res.json({
      success: true,
      data: { admin }
    });
  } catch (error) {
    logger.error('Failed to get admin profile', { error: error.message });
    next(error);
  }
};

// Debug function to list all admins
const listAllAdmins = async (req, res, next) => {
  try {
    const admins = await Admin.find({}, 'name email role isActive createdAt').sort({ createdAt: -1 });
    
    logger.info('Admin list requested', { count: admins.length });
    
    res.json({
      success: true,
      data: {
        admins,
        count: admins.length
      }
    });
  } catch (error) {
    logger.error('Failed to list admins', { error: error.message });
    next(error);
  }
};

// Debug function to check database connection and indexes
const debugDatabase = async (req, res, next) => {
  try {
    const Admin = require('../models/admin.model');
    
    // Check database connection
    const dbState = require('mongoose').connection.readyState;
    const dbStates = {
      0: 'disconnected',
      1: 'connected',
      2: 'connecting',
      3: 'disconnecting'
    };
    
    // Get collection info
    const collection = Admin.collection;
    const indexes = await collection.indexes();
    const count = await Admin.countDocuments();
    
    // Get all admins for debugging
    const admins = await Admin.find({}, 'name email createdAt').sort({ createdAt: -1 });
    
    res.json({
      success: true,
      debug: {
        database: {
          state: dbStates[dbState],
          name: collection.db.databaseName,
          collection: collection.collectionName
        },
        indexes: indexes,
        adminCount: count,
        admins: admins
      }
    });
  } catch (error) {
    logger.error('Debug database failed', { error: error.message });
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// Get all unverified drivers
const getUnverifiedDrivers = async (req, res, next) => {
  try {
    const drivers = await Driver.find({ isVerified: false, isActive: true })
      .select('-password')
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      data: drivers,
      count: drivers.length
    });
  } catch (error) {
    logger.error('Failed to get unverified drivers', { error: error.message });
    next(error);
  }
};

// Get all unverified connectors
const getUnverifiedConnectors = async (req, res, next) => {
  try {
    const connectors = await Connector.find({ isVerified: false, isActive: true })
      .select('-password')
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      data: connectors,
      count: connectors.length
    });
  } catch (error) {
    logger.error('Failed to get unverified connectors', { error: error.message });
    next(error);
  }
};

// Verify a driver
const verifyDriver = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const driver = await Driver.findById(id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }
    
    driver.isVerified = true;
    await driver.save();
    
    logger.info('Driver verified', { driverId: id, adminId: req.user.id });
    
    res.json({
      success: true,
      message: 'Driver verified successfully',
      data: driver
    });
  } catch (error) {
    logger.error('Failed to verify driver', { error: error.message });
    next(error);
  }
};

// Verify a connector
const verifyConnector = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const connector = await Connector.findById(id);
    if (!connector) {
      return res.status(404).json({
        success: false,
        message: 'Connector not found'
      });
    }
    
    connector.isVerified = true;
    await connector.save();
    
    logger.info('Connector verified', { connectorId: id, adminId: req.user.id });
    
    res.json({
      success: true,
      message: 'Connector verified successfully',
      data: connector
    });
  } catch (error) {
    logger.error('Failed to verify connector', { error: error.message });
    next(error);
  }
};

// Get all drivers (for admin)
const getAllDrivers = async (req, res, next) => {
  try {
    const drivers = await Driver.find({ isActive: true })
      .select('-password')
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      data: drivers,
      count: drivers.length
    });
  } catch (error) {
    logger.error('Failed to get all drivers', { error: error.message });
    next(error);
  }
};

// Get all connectors (for admin)
const getAllConnectors = async (req, res, next) => {
  try {
    const connectors = await Connector.find({ isActive: true })
      .select('-password')
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      data: connectors,
      count: connectors.length
    });
  } catch (error) {
    logger.error('Failed to get all connectors', { error: error.message });
    next(error);
  }
};

module.exports = {
  register,
  login,
  getProfile,
  listAllAdmins,
  debugDatabase,
  getUnverifiedDrivers,
  getUnverifiedConnectors,
  verifyDriver,
  verifyConnector,
  getAllDrivers,
  getAllConnectors
};