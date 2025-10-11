const express = require('express');
const {
  getPriceEstimation,
  getRoutes,
  getRouteById,
  createRoute,
  updateRoutePricing,
  getBulkPriceEstimation
} = require('../controllers/pricing.controllers');
const { authenticate, authorize } = require('../middlewares/auth.middleware');
const { validate } = require('../controllers/validators/bus-timetable.validators'); // Reusing validate middleware

const router = express.Router();

// Public routes (no authentication required)
router.get('/estimate', getPriceEstimation);
router.get('/routes', getRoutes);
router.get('/routes/:id', getRouteById);
router.post('/estimate/bulk', getBulkPriceEstimation);

// Admin-only routes (authentication and authorization required)
router.post('/routes', authenticate, authorize('admin', 'super_admin'), createRoute);
router.put('/routes/:id/pricing', authenticate, authorize('admin', 'super_admin'), updateRoutePricing);

module.exports = router;
