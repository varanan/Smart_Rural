const express = require('express');
const { authenticate, authorize } = require('../middlewares/auth.middleware');
const {
  createBooking,
  getMyBookings,
  getAvailableSeats,
  cancelBooking
} = require('../controllers/booking.controllers');

const router = express.Router();

// All booking routes require authentication
router.use(authenticate);

// Create a new booking (passengers only)
router.post('/', authorize('passenger'), createBooking);

// Get my bookings (passengers only)
router.get('/my-bookings', authorize('passenger'), getMyBookings);

// Get available seats for a bus on a specific date
router.get('/available-seats', getAvailableSeats);

// Cancel a booking (passengers only)
router.patch('/:bookingId/cancel', authorize('passenger'), cancelBooking);

module.exports = router;
