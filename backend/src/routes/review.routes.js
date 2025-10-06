const express = require('express');
const {
  createReview,
  getReviewsByBus,
  getMyReviews,
  updateReview,
  deleteReview,
  getAllReviews
} = require('../controllers/review.controllers');
const { authenticate, authorize } = require('../middlewares/auth.middleware');
const { createReviewSchema, updateReviewSchema, validate } = require('../controllers/validators/review.validators');

const router = express.Router();

// Passenger routes
router.post('/', authenticate, authorize('passenger'), validate(createReviewSchema), createReview);
router.get('/my-reviews', authenticate, authorize('passenger'), getMyReviews);
router.put('/:id', authenticate, authorize('passenger'), validate(updateReviewSchema), updateReview);
router.delete('/:id', authenticate, authorize('passenger', 'admin', 'super_admin'), deleteReview);

// Public route - anyone can view reviews for a bus
router.get('/bus/:busId', getReviewsByBus);

// Admin, Driver, Connector can view all reviews
router.get('/', authenticate, authorize('admin', 'super_admin', 'driver', 'connector'), getAllReviews);

module.exports = router;