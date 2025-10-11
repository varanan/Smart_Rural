const Booking = require('../models/booking.model');
const BusTimeTable = require('../models/bus-timetable.model');
const PricingService = require('./pricing.service');
const logger = require('../utils/logger');

const TOTAL_SEATS_PER_BUS = 40;

const generateBookingReference = () => {
  const timestamp = Date.now().toString();
  const random = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `BK-${timestamp}-${random}`;
};

const createBooking = async (input) => {
  try {
    const { passengerId, timetableId, seatNumbers, journeyDate, totalAmount } = input;

    // Validate timetable exists and populate route
    const timetable = await BusTimeTable.findById(timetableId).populate('route');
    if (!timetable) {
      throw new Error('Bus timetable not found');
    }

    if (!timetable.isActive) {
      throw new Error('This bus timetable is no longer active');
    }

    // Parse journey date
    const journey = new Date(journeyDate);

    // Check seat availability
    const bookedSeats = await getBookedSeats(timetableId, journeyDate);
    const unavailableSeats = seatNumbers.filter(seat => bookedSeats.includes(seat));

    if (unavailableSeats.length > 0) {
      throw new Error(`Seats ${unavailableSeats.join(', ')} are already booked`);
    }

    // Calculate pricing using the new pricing service
    let pricingDetails;
    try {
      pricingDetails = await PricingService.calculatePrice(
        timetable.from,
        timetable.to,
        timetable.busType,
        journey,
        seatNumbers.length
      );
    } catch (pricingError) {
      logger.warn('Failed to calculate dynamic pricing, falling back to legacy pricing', {
        error: pricingError.message,
        timetableId,
        from: timetable.from,
        to: timetable.to
      });
      
      // Fallback to legacy pricing if route not found
      const pricePerSeat = calculateSeatPriceLegacy(timetable.busType);
      pricingDetails = {
        pricePerSeat,
        totalPrice: pricePerSeat * seatNumbers.length,
        currency: 'LKR',
        route: {
          from: timetable.from,
          to: timetable.to,
          distance: null,
          routeCode: 'LEGACY'
        }
      };
    }

    // Create booking
    const booking = new Booking({
      passengerId,
      timetableId,
      seatNumbers,
      totalSeats: seatNumbers.length,
      journeyDate: journey,
      bookingReference: generateBookingReference(),
      pricing: {
        pricePerSeat: pricingDetails.pricePerSeat,
        totalAmount: pricingDetails.totalPrice,
        currency: pricingDetails.currency || 'LKR'
      },
      bookingStatus: 'pending',
      paymentStatus: 'pending'
    });

    await booking.save();

    logger.info('Booking created successfully', {
      bookingId: booking._id,
      bookingReference: booking.bookingReference,
      passengerId,
      seats: seatNumbers.length,
      totalPrice: pricingDetails.totalPrice,
      pricePerSeat: pricingDetails.pricePerSeat,
      routeCode: pricingDetails.route?.routeCode
    });

    return booking;
  } catch (error) {
    logger.error('Error creating booking', { error: error.message });
    throw error;
  }
};

const getBookings = async (filters = {}) => {
  try {
    const {
      passengerId,
      bookingStatus,
      paymentStatus,
      timetableId,
      fromDate,
      toDate,
      page = 1,
      limit = 10
    } = filters;

    const query = {};

    if (passengerId) query.passengerId = passengerId;
    if (bookingStatus) query.bookingStatus = bookingStatus;
    if (paymentStatus) query.paymentStatus = paymentStatus;
    if (timetableId) query.timetableId = timetableId;

    if (fromDate || toDate) {
      query.journeyDate = {};
      if (fromDate) query.journeyDate.$gte = new Date(fromDate);
      if (toDate) query.journeyDate.$lte = new Date(toDate);
    }

    const skip = (page - 1) * limit;

    const bookings = await Booking.find(query)
      .populate('timetableId', 'from to startTime endTime busType')
      .populate('passengerId', 'fullName email phone')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Booking.countDocuments(query);

    logger.info('Bookings retrieved successfully', {
      count: bookings.length,
      total,
      filters: query
    });

    return {
      bookings,
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / limit)
    };
  } catch (error) {
    logger.error('Error retrieving bookings', { error: error.message });
    throw error;
  }
};

const getBookingById = async (bookingId, passengerId = null) => {
  try {
    const query = { _id: bookingId };
    if (passengerId) query.passengerId = passengerId;

    const booking = await Booking.findOne(query)
      .populate('timetableId', 'from to startTime endTime busType')
      .populate('passengerId', 'fullName email phone')
      .populate('paymentId');

    if (!booking) {
      throw new Error('Booking not found');
    }

    logger.info('Booking retrieved successfully', { bookingId });

    return booking;
  } catch (error) {
    logger.error('Error retrieving booking', { error: error.message, bookingId });
    throw error;
  }
};

const cancelBooking = async (bookingId, passengerId) => {
  try {
    const booking = await Booking.findOne({
      _id: bookingId,
      passengerId
    });

    if (!booking) {
      throw new Error('Booking not found');
    }

    if (booking.bookingStatus === 'cancelled') {
      throw new Error('Booking is already cancelled');
    }

    if (booking.bookingStatus === 'completed') {
      throw new Error('Cannot cancel completed booking');
    }

    // Check if journey date has passed
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    if (booking.journeyDate < today) {
      throw new Error('Cannot cancel booking for past journey');
    }

    booking.bookingStatus = 'cancelled';
    await booking.save();

    logger.info('Booking cancelled successfully', {
      bookingId,
      bookingReference: booking.bookingReference
    });

    return booking;
  } catch (error) {
    logger.error('Error cancelling booking', { error: error.message, bookingId });
    throw error;
  }
};

const getBookedSeats = async (timetableId, journeyDate) => {
  try {
    const journey = new Date(journeyDate);
    journey.setHours(0, 0, 0, 0);
    
    const nextDay = new Date(journey);
    nextDay.setDate(nextDay.getDate() + 1);

    const bookings = await Booking.find({
      timetableId,
      journeyDate: {
        $gte: journey,
        $lt: nextDay
      },
      bookingStatus: { $in: ['pending', 'confirmed'] }
    }).select('seatNumbers');

    const bookedSeats = bookings.reduce((seats, booking) => {
      return seats.concat(booking.seatNumbers);
    }, []);

    return bookedSeats;
  } catch (error) {
    logger.error('Error retrieving booked seats', { error: error.message });
    throw error;
  }
};

const getSeatAvailability = async (timetableId, journeyDate) => {
  try {
    const timetable = await BusTimeTable.findById(timetableId).populate('route');
    if (!timetable) {
      throw new Error('Bus timetable not found');
    }

    const bookedSeats = await getBookedSeats(timetableId, journeyDate);
    const totalSeats = TOTAL_SEATS_PER_BUS;
    const availableSeats = totalSeats - bookedSeats.length;

    // Calculate pricing for this route
    let pricingInfo = null;
    try {
      const journey = new Date(journeyDate);
      pricingInfo = await PricingService.calculatePrice(
        timetable.from,
        timetable.to,
        timetable.busType,
        journey,
        1 // Price for 1 seat
      );
    } catch (pricingError) {
      logger.warn('Failed to calculate pricing for seat availability', {
        error: pricingError.message,
        timetableId
      });
    }

    logger.info('Seat availability retrieved', {
      timetableId,
      totalSeats,
      bookedSeats: bookedSeats.length,
      availableSeats,
      hasPricing: !!pricingInfo
    });

    return {
      totalSeats,
      bookedSeats,
      availableSeats,
      seatMap: generateSeatMap(bookedSeats),
      pricing: pricingInfo ? {
        pricePerSeat: pricingInfo.pricePerSeat,
        currency: pricingInfo.currency,
        route: pricingInfo.route
      } : null
    };
  } catch (error) {
    logger.error('Error retrieving seat availability', { error: error.message });
    throw error;
  }
};

// Legacy pricing function for fallback
const calculateSeatPriceLegacy = (busType) => {
  const BASE_PRICE_PER_SEAT = 100;
  const priceMultipliers = {
    'Normal': 1.0,
    'Semi-Luxury': 1.5,
    'Express': 1.3,
    'Luxury': 2.0,
    'Intercity': 1.2
  };

  const multiplier = priceMultipliers[busType] || 1.0;
  return Math.round(BASE_PRICE_PER_SEAT * multiplier);
};

const generateSeatMap = (bookedSeats) => {
  const rows = 10;
  const seatsPerRow = 4;
  const seatMap = [];

  for (let row = 1; row <= rows; row++) {
    const rowSeats = [];
    const seatLetters = ['A', 'B', 'C', 'D'];
    
    for (let col = 0; col < seatsPerRow; col++) {
      const seatNumber = `${seatLetters[col]}${row}`;
      rowSeats.push({
        seatNumber,
        isBooked: bookedSeats.includes(seatNumber),
        isAvailable: !bookedSeats.includes(seatNumber)
      });
    }
    
    seatMap.push(rowSeats);
  }

  return seatMap;
};

const updateBookingStatus = async (bookingId, status) => {
  try {
    const validStatuses = ['pending', 'confirmed', 'cancelled', 'completed'];
    if (!validStatuses.includes(status)) {
      throw new Error('Invalid booking status');
    }

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      throw new Error('Booking not found');
    }

    booking.bookingStatus = status;
    await booking.save();

    logger.info('Booking status updated', { bookingId, status });

    return booking;
  } catch (error) {
    logger.error('Error updating booking status', { error: error.message, bookingId });
    throw error;
  }
};

module.exports = {
  createBooking,
  getBookings,
  getBookingById,
  cancelBooking,
  getBookedSeats,
  getSeatAvailability,
  calculateSeatPriceLegacy,
  updateBookingStatus
};

