const express = require('express');
const { authenticateToken } = require('../middlewares/auth.middleware');
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
router.post('/', authenticateToken, createRideShare);
router.get('/connector', authenticateToken, getConnectorRides);
router.patch('/:id/status', authenticateToken, updateRideStatus);
router.post('/request', authenticateToken, requestRide);
router.post('/:id/respond', authenticateToken, respondToRequest);
router.get('/passenger', authenticateToken, getPassengerRides);

module.exports = router;