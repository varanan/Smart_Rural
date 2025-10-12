const bookingService = require('../services/booking.service');
const paymentService = require('../services/payment.service');
const logger = require('../utils/logger');

// Create new booking
const createBooking = async (req, res, next) => {
  try {
    const { timetableId, seatNumbers, journeyDate, totalAmount } = req.body;
    const passengerId = req.user._id;

    const booking = await bookingService.createBooking({
      passengerId,
      timetableId,
      seatNumbers,
      journeyDate,
      totalAmount
    });

    await booking.populate('timetableId', 'from to startTime endTime busType');
    await booking.populate('passengerId', 'fullName email phone');

    res.status(201).json({
      success: true,
      message: 'Booking created successfully',
      data: booking
    });
  } catch (error) {
    logger.error('Error creating booking', { error: error.message });
    next(error);
  }
};

// Get all bookings for authenticated user
const getMyBookings = async (req, res, next) => {
  try {
    const passengerId = req.user._id;
    const { bookingStatus, paymentStatus, page, limit } = req.query;

    const result = await bookingService.getBookings({
      passengerId,
      bookingStatus,
      paymentStatus,
      page,
      limit
    });

    res.json({
      success: true,
      message: 'Bookings retrieved successfully',
      data: result.bookings,
      pagination: {
        current: result.page,
        pages: result.totalPages,
        total: result.total
      }
    });
  } catch (error) {
    logger.error('Error retrieving bookings', { error: error.message });
    next(error);
  }
};

// Get all bookings (Admin only)
const getAllBookings = async (req, res, next) => {
  try {
    const { passengerId, bookingStatus, paymentStatus, timetableId, fromDate, toDate, page, limit } = req.query;

    const result = await bookingService.getBookings({
      passengerId,
      bookingStatus,
      paymentStatus,
      timetableId,
      fromDate,
      toDate,
      page,
      limit
    });

    res.json({
      success: true,
      message: 'Bookings retrieved successfully',
      data: result.bookings,
      pagination: {
        current: result.page,
        pages: result.totalPages,
        total: result.total
      }
    });
  } catch (error) {
    logger.error('Error retrieving bookings', { error: error.message });
    next(error);
  }
};

// Get single booking by ID
const getBookingById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const passengerId = req.user.role === 'passenger' ? req.user._id : null;

    const booking = await bookingService.getBookingById(id, passengerId);

    res.json({
      success: true,
      message: 'Booking retrieved successfully',
      data: booking
    });
  } catch (error) {
    logger.error('Error retrieving booking', { error: error.message });
    if (error.message === 'Booking not found') {
      return res.status(404).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

// Cancel booking
const cancelBooking = async (req, res, next) => {
  try {
    const { id } = req.params;
    const passengerId = req.user._id;

    const booking = await bookingService.cancelBooking(id, passengerId);

    res.json({
      success: true,
      message: 'Booking cancelled successfully',
      data: booking
    });
  } catch (error) {
    logger.error('Error cancelling booking', { error: error.message });
    if (error.message === 'Booking not found') {
      return res.status(404).json({
        success: false,
        message: error.message
      });
    }
    if (error.message.includes('Cannot cancel')) {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

// Get seat availability
const getSeatAvailability = async (req, res, next) => {
  try {
    const { timetableId, journeyDate } = req.query;

    const availability = await bookingService.getSeatAvailability(timetableId, journeyDate);

    res.json({
      success: true,
      message: 'Seat availability retrieved successfully',
      data: availability
    });
  } catch (error) {
    logger.error('Error retrieving seat availability', { error: error.message });
    if (error.message === 'Bus timetable not found') {
      return res.status(404).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

// Process payment for booking
const processPayment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { paymentMethod, cardNumber } = req.body;
    const passengerId = req.user._id;

    // Verify booking belongs to user
    const booking = await bookingService.getBookingById(id, passengerId);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    const result = await paymentService.processPayment({
      bookingId: id,
      paymentMethod,
      cardNumber
    });

    res.json({
      success: true,
      message: 'Payment processed successfully',
      data: {
        payment: result.payment,
        booking: result.booking
      }
    });
  } catch (error) {
    logger.error('Error processing payment', { error: error.message });
    if (error.message.includes('already been paid') || error.message.includes('cancelled')) {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }
    if (error.message.includes('declined') || error.message.includes('insufficient') || error.message.includes('expired')) {
      return res.status(402).json({
        success: false,
        message: error.message,
        error: 'payment_failed'
      });
    }
    next(error);
  }
};

// Get payment by booking ID
const getPaymentByBookingId = async (req, res, next) => {
  try {
    const { id } = req.params;
    const passengerId = req.user.role === 'passenger' ? req.user._id : null;

    // Verify booking belongs to user
    const booking = await bookingService.getBookingById(id, passengerId);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    const payment = await paymentService.getPaymentByBookingId(id);

    res.json({
      success: true,
      message: 'Payment retrieved successfully',
      data: payment
    });
  } catch (error) {
    logger.error('Error retrieving payment', { error: error.message });
    if (error.message === 'Payment not found for this booking') {
      return res.status(404).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

// Refund payment (Admin only)
const refundPayment = async (req, res, next) => {
  try {
    const { paymentId } = req.params;

    const payment = await paymentService.refundPayment(paymentId);

    res.json({
      success: true,
      message: 'Payment refunded successfully',
      data: payment
    });
  } catch (error) {
    logger.error('Error refunding payment', { error: error.message });
    if (error.message === 'Payment not found') {
      return res.status(404).json({
        success: false,
        message: error.message
      });
    }
    if (error.message.includes('already been refunded') || error.message.includes('Can only refund')) {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

module.exports = {
  createBooking,
  getMyBookings,
  getAllBookings,
  getBookingById,
  cancelBooking,
  getSeatAvailability,
  processPayment,
  getPaymentByBookingId,
  refundPayment
};

