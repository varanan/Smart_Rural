const express = require('express');
const { 
  register, 
  login, 
  getProfile,
  listAllAdmins,
  debugDatabase
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

module.exports = router;
