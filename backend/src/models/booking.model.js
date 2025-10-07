const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  busId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'BusTimeTable',
    required: [true, 'Bus ID is required']
  },
  passengerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Passenger',
    required: [true, 'Passenger ID is required']
  },
  passengerName: {
    type: String,
    required: [true, 'Passenger name is required'],
    trim: true
  },
  passengerPhone: {
    type: String,
    required: [true, 'Passenger phone is required'],
    trim: true,
    match: [/^0\d{9}$/, 'Please enter a valid Sri Lankan phone number']
  },
  seatNumber: {
    type: Number,
    required: [true, 'Seat number is required'],
    min: [1, 'Seat number must be at least 1'],
    max: [50, 'Seat number cannot exceed 50']
  },
  bookingDate: {
    type: Date,
    required: [true, 'Booking date is required']
  },
  travelDate: {
    type: Date,
    required: [true, 'Travel date is required']
  },
  status: {
    type: String,
    enum: ['confirmed', 'cancelled', 'completed'],
    default: 'confirmed'
  },
  fare: {
    type: Number,
    required: [true, 'Fare is required'],
    min: [0, 'Fare cannot be negative']
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Ensure unique booking per seat per bus per travel date
bookingSchema.index({ busId: 1, seatNumber: 1, travelDate: 1 }, { unique: true });
bookingSchema.index({ passengerId: 1 });
bookingSchema.index({ status: 1 });
bookingSchema.index({ travelDate: 1 });

module.exports = mongoose.model('Booking', bookingSchema);
