const express = require('express');
const { authenticate } = require('../middlewares/auth.middleware'); // Changed from authenticateToken to authenticate
const {
  createRideShare,
  getRideShares,
  getConnectorRides,
  updateRideStatus,
  requestRide,
  respondToRequest,
  getPassengerRides
} = require('../controllers/ride-share.controllers');

const router = express.Router();

// Public routes
router.get('/', getRideShares);

// Protected routes
router.post('/', authenticate, createRideShare); // Changed authenticateToken to authenticate
router.get('/connector', authenticate, getConnectorRides);
router.patch('/:id/status', authenticate, updateRideStatus);
router.post('/request', authenticate, requestRide);
router.post('/:id/respond', authenticate, respondToRequest);
router.get('/passenger', authenticate, getPassengerRides);

module.exports = router;