const express = require('express');
const { 
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
} = require('../controllers/admin.controllers');
const { 
  adminRegisterSchema, 
  adminLoginSchema, 
  validate 
} = require('../controllers/validators/admin.validators');
const { authenticate } = require('../middlewares/auth.middleware');

const router = express.Router();

// Public routes
router.post('/register', validate(adminRegisterSchema), register);
router.post('/login', validate(adminLoginSchema), login);

// Protected routes
router.get('/profile', authenticate, getProfile);

// Debug routes (remove in production)
router.get('/list', listAllAdmins);
router.get('/debug', debugDatabase);

// Verification routes
router.get('/drivers/unverified', authenticate, getUnverifiedDrivers);
router.get('/connectors/unverified', authenticate, getUnverifiedConnectors);
router.get('/drivers', authenticate, getAllDrivers);
router.get('/connectors', authenticate, getAllConnectors);
router.put('/drivers/:id/verify', authenticate, verifyDriver);
router.put('/connectors/:id/verify', authenticate, verifyConnector);

module.exports = router;