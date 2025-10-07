const Booking = require('../models/booking.model');
const BusTimeTable = require('../models/bus-timetable.model');
const logger = require('../utils/logger');

// Create a new booking
const createBooking = async (req, res, next) => {
  try {
    const { busId, seatNumber, travelDate, passengerName, passengerPhone } = req.body;
    const passengerId = req.user._id;

    // Validate bus exists and is active
    const bus = await BusTimeTable.findById(busId);
    if (!bus || !bus.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Bus not found or inactive'
      });
    }

    // Set default values if missing
    const totalSeats = bus.totalSeats || 30;
    const fare = bus.fare || 50;

    // Validate seat number
    if (seatNumber < 1 || seatNumber > totalSeats) {
      return res.status(400).json({
        success: false,
        message: `Seat number must be between 1 and ${totalSeats}`
      });
    }

    // Check if seat is already booked for the travel date
    const existingBooking = await Booking.findOne({
      busId,
      seatNumber,
      travelDate: new Date(travelDate),
      status: 'confirmed'
    });

    if (existingBooking) {
      return res.status(400).json({
        success: false,
        message: 'Seat is already booked for this date'
      });
    }

    // Create booking
    const booking = new Booking({
      busId,
      passengerId,
      passengerName,
      passengerPhone,
      seatNumber,
      bookingDate: new Date(),
      travelDate: new Date(travelDate),
      fare: fare
    });

    await booking.save();
    await booking.populate('busId', 'from to startTime endTime busType');

    logger.info('Booking created successfully', {
      bookingId: booking._id,
      passengerId,
      busId,
      seatNumber
    });

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

// Get passenger's bookings
const getMyBookings = async (req, res, next) => {
  try {
    const passengerId = req.user._id;
    const { status, page = 1, limit = 10 } = req.query;

    const filter = { passengerId, isActive: true };
    if (status) {
      filter.status = status;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const bookings = await Booking.find(filter)
      .populate('busId', 'from to startTime endTime busType')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Booking.countDocuments(filter);

    logger.info('Passenger bookings retrieved', {
      passengerId,
      count: bookings.length
    });

    res.json({
      success: true,
      message: 'Bookings retrieved successfully',
      data: bookings,
      pagination: {
        current: parseInt(page),
        pages: Math.ceil(total / parseInt(limit)),
        total
      }
    });
  } catch (error) {
    logger.error('Error retrieving bookings', { error: error.message });
    next(error);
  }
};

// Get available seats for a bus on a specific date
const getAvailableSeats = async (req, res, next) => {
  try {
    const { busId, travelDate } = req.query;

    if (!busId || !travelDate) {
      return res.status(400).json({
        success: false,
        message: 'Bus ID and travel date are required'
      });
    }

    // Validate ObjectId format
    if (!busId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid bus ID format'
      });
    }

    // Get bus details
    const bus = await BusTimeTable.findById(busId);
    if (!bus || !bus.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Bus route not found or inactive'
      });
    }

    // Set default values if missing
    const totalSeats = bus.totalSeats || 30;
    const fare = bus.fare || 50;

    // Parse travel date
    let parsedTravelDate;
    try {
      parsedTravelDate = new Date(travelDate);
      // Set to start of day to match bookings
      parsedTravelDate.setHours(0, 0, 0, 0);
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'Invalid travel date format'
      });
    }

    // Get booked seats for the date
    const bookedSeats = await Booking.find({
      busId,
      travelDate: {
        $gte: parsedTravelDate,
        $lt: new Date(parsedTravelDate.getTime() + 24 * 60 * 60 * 1000)
      },
      status: 'confirmed'
    }).select('seatNumber');

    const bookedSeatNumbers = bookedSeats.map(booking => booking.seatNumber);
    const availableSeats = [];

    for (let i = 1; i <= totalSeats; i++) {
      if (!bookedSeatNumbers.includes(i)) {
        availableSeats.push(i);
      }
    }

    logger.info('Available seats retrieved', {
      busId,
      travelDate: parsedTravelDate,
      totalSeats,
      bookedCount: bookedSeatNumbers.length,
      availableCount: availableSeats.length
    });

    res.json({
      success: true,
      message: 'Available seats retrieved successfully',
      data: {
        totalSeats,
        bookedSeats: bookedSeatNumbers,
        availableSeats,
        fare
      }
    });
  } catch (error) {
    logger.error('Error retrieving available seats', { error: error.message });
    next(error);
  }
};

// Cancel a booking
const cancelBooking = async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    const passengerId = req.user._id;

    const booking = await Booking.findOne({
      _id: bookingId,
      passengerId,
      isActive: true
    });

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    if (booking.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Booking is already cancelled'
      });
    }

    // Check if travel date is in the future (allow cancellation only before travel)
    const now = new Date();
    const travelDate = new Date(booking.travelDate);
    
    if (travelDate <= now) {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel booking for past or current travel date'
      });
    }

    booking.status = 'cancelled';
    await booking.save();

    logger.info('Booking cancelled', {
      bookingId,
      passengerId
    });

    res.json({
      success: true,
      message: 'Booking cancelled successfully',
      data: booking
    });
  } catch (error) {
    logger.error('Error cancelling booking', { error: error.message });
    next(error);
  }
};

module.exports = {
  createBooking,
  getMyBookings,
  getAvailableSeats,
  cancelBooking
};
