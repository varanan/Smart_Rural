const Payment = require('../models/payment.model');
const Booking = require('../models/booking.model');
const MockPaymentService = require('./mock-payment.service');
const logger = require('../utils/logger');

const processPayment = async (input) => {
  try {
    const { bookingId, paymentMethod, cardNumber = '4242424242424242' } = input;

    // Validate booking exists
    const booking = await Booking.findById(bookingId);
    if (!booking) {
      throw new Error('Booking not found');
    }

    if (booking.paymentStatus === 'paid') {
      throw new Error('Booking has already been paid');
    }

    if (booking.bookingStatus === 'cancelled') {
      throw new Error('Cannot process payment for cancelled booking');
    }

    // Create payment intent (mock)
    const paymentIntent = await MockPaymentService.createPaymentIntent(
      booking.pricing.totalAmount,
      booking.pricing.currency
    );

    // Confirm payment (mock)
    const paymentResult = await MockPaymentService.confirmPayment(
      paymentIntent.id,
      cardNumber
    );

    // Check payment status
    if (paymentResult.status === 'succeeded') {
      // Create payment record
      const payment = new Payment({
        bookingId: booking._id,
        amount: booking.pricing.totalAmount,
        currency: booking.pricing.currency,
        paymentMethod,
        paymentStatus: 'completed',
        transactionId: MockPaymentService.generateTransactionId(),
        mockCardNumber: cardNumber.slice(-4),
        processedAt: new Date()
      });

      await payment.save();

      // Update booking
      booking.paymentStatus = 'paid';
      booking.paymentId = payment._id;
      booking.bookingStatus = 'confirmed';
      await booking.save();

      logger.info('Payment processed successfully', {
        paymentId: payment._id,
        bookingId,
        amount: payment.amount
      });

      return {
        success: true,
        payment,
        booking
      };
    } else {
      // Payment failed
      const failureReason = paymentResult.last_payment_error?.message || 'Payment failed';
      
      const payment = new Payment({
        bookingId: booking._id,
        amount: booking.pricing.totalAmount,
        currency: booking.pricing.currency,
        paymentMethod,
        paymentStatus: 'failed',
        transactionId: MockPaymentService.generateTransactionId(),
        mockCardNumber: cardNumber.slice(-4),
        failureReason,
        processedAt: new Date()
      });

      await payment.save();

      // Update booking
      booking.paymentStatus = 'failed';
      await booking.save();

      logger.error('Payment failed', {
        bookingId,
        reason: failureReason
      });

      throw new Error(failureReason);
    }
  } catch (error) {
    logger.error('Error processing payment', { error: error.message });
    throw error;
  }
};

const getPaymentByBookingId = async (bookingId) => {
  try {
    const payment = await Payment.findOne({ bookingId })
      .populate('bookingId');

    if (!payment) {
      throw new Error('Payment not found for this booking');
    }

    logger.info('Payment retrieved successfully', { paymentId: payment._id });

    return payment;
  } catch (error) {
    logger.error('Error retrieving payment', { error: error.message, bookingId });
    throw error;
  }
};

const getPaymentById = async (paymentId) => {
  try {
    const payment = await Payment.findById(paymentId)
      .populate('bookingId');

    if (!payment) {
      throw new Error('Payment not found');
    }

    logger.info('Payment retrieved successfully', { paymentId });

    return payment;
  } catch (error) {
    logger.error('Error retrieving payment', { error: error.message, paymentId });
    throw error;
  }
};

const refundPayment = async (paymentId) => {
  try {
    const payment = await Payment.findById(paymentId).populate('bookingId');
    
    if (!payment) {
      throw new Error('Payment not found');
    }

    if (payment.paymentStatus === 'refunded') {
      throw new Error('Payment has already been refunded');
    }

    if (payment.paymentStatus !== 'completed') {
      throw new Error('Can only refund completed payments');
    }

    // Process refund (mock)
    await MockPaymentService.refundPayment(payment.transactionId, payment.amount);

    // Update payment
    payment.paymentStatus = 'refunded';
    await payment.save();

    // Update booking
    const booking = await Booking.findById(payment.bookingId);
    if (booking) {
      booking.paymentStatus = 'refunded';
      booking.bookingStatus = 'cancelled';
      await booking.save();
    }

    logger.info('Payment refunded successfully', {
      paymentId,
      bookingId: payment.bookingId
    });

    return payment;
  } catch (error) {
    logger.error('Error refunding payment', { error: error.message, paymentId });
    throw error;
  }
};

const getAllPayments = async (filters = {}) => {
  try {
    const {
      paymentStatus,
      paymentMethod,
      fromDate,
      toDate,
      page = 1,
      limit = 10
    } = filters;

    const query = {};

    if (paymentStatus) query.paymentStatus = paymentStatus;
    if (paymentMethod) query.paymentMethod = paymentMethod;

    if (fromDate || toDate) {
      query.createdAt = {};
      if (fromDate) query.createdAt.$gte = new Date(fromDate);
      if (toDate) query.createdAt.$lte = new Date(toDate);
    }

    const skip = (page - 1) * limit;

    const payments = await Payment.find(query)
      .populate({
        path: 'bookingId',
        populate: {
          path: 'timetableId passengerId',
          select: 'from to startTime fullName email'
        }
      })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Payment.countDocuments(query);

    logger.info('Payments retrieved successfully', {
      count: payments.length,
      total,
      filters: query
    });

    return {
      payments,
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / limit)
    };
  } catch (error) {
    logger.error('Error retrieving payments', { error: error.message });
    throw error;
  }
};

module.exports = {
  processPayment,
  getPaymentByBookingId,
  getPaymentById,
  refundPayment,
  getAllPayments
};

