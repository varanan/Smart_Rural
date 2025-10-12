const express = require('express');
const {
  createBooking,
  getMyBookings,
  getAllBookings,
  getBookingById,
  cancelBooking,
  getSeatAvailability,
  processPayment,
  getPaymentByBookingId,
  refundPayment
} = require('../controllers/booking.controllers');
const { authenticate, authorize } = require('../middlewares/auth.middleware');
const {
  bookingSchema,
  paymentSchema,
  seatAvailabilitySchema,
  validate
} = require('../controllers/validators/booking.validators');

const router = express.Router();

// Public routes
router.get('/seat-availability', validate(seatAvailabilitySchema), getSeatAvailability);

// Protected routes (Passenger)
router.post('/', authenticate, authorize('passenger'), validate(bookingSchema), createBooking);
router.get('/my-bookings', authenticate, authorize('passenger'), getMyBookings);
router.get('/:id', authenticate, getBookingById);
router.delete('/:id', authenticate, authorize('passenger'), cancelBooking);

// Payment routes (Passenger)
router.post('/:id/payment', authenticate, authorize('passenger'), validate(paymentSchema), processPayment);
router.get('/:id/payment', authenticate, getPaymentByBookingId);

// Admin routes
router.get('/', authenticate, authorize('admin', 'super_admin'), getAllBookings);
router.post('/payment/:paymentId/refund', authenticate, authorize('admin', 'super_admin'), refundPayment);

module.exports = router;

