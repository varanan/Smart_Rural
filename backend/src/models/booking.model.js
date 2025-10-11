const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  bookingReference: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  passengerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Passenger',
    required: [true, 'Passenger ID is required']
  },
  timetableId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'BusTimeTable',
    required: [true, 'Timetable ID is required']
  },
  seatNumbers: {
    type: [String],
    required: [true, 'At least one seat is required'],
    validate: {
      validator: function(seats) {
        return seats && seats.length > 0;
      },
      message: 'At least one seat must be selected'
    }
  },
  totalSeats: {
    type: Number,
    required: true,
    min: [1, 'Total seats must be at least 1']
  },
  bookingStatus: {
    type: String,
    required: true,
    enum: ['pending', 'confirmed', 'cancelled', 'completed'],
    default: 'pending'
  },
  journeyDate: {
    type: Date,
    required: [true, 'Journey date is required']
  },
  pricing: {
    pricePerSeat: {
      type: Number,
      required: [true, 'Price per seat is required'],
      min: [0, 'Price cannot be negative']
    },
    totalAmount: {
      type: Number,
      required: [true, 'Total amount is required'],
      min: [0, 'Total amount cannot be negative']
    },
    currency: {
      type: String,
      default: 'LKR',
      uppercase: true
    }
  },
  paymentStatus: {
    type: String,
    required: true,
    enum: ['pending', 'paid', 'failed', 'refunded'],
    default: 'pending'
  },
  paymentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Payment',
    default: null
  }
}, {
  timestamps: true
});

// Generate booking reference before saving
bookingSchema.pre('save', async function(next) {
  if (this.isNew && !this.bookingReference) {
    const date = new Date();
    const dateStr = date.toISOString().split('T')[0].replace(/-/g, '');
    const randomStr = Math.random().toString(36).substring(2, 10).toUpperCase();
    this.bookingReference = `BK-${dateStr}-${randomStr}`;
  }
  next();
});

// Calculate total seats before saving
bookingSchema.pre('save', function(next) {
  if (this.seatNumbers && this.seatNumbers.length > 0) {
    this.totalSeats = this.seatNumbers.length;
  }
  next();
});

// Create indexes for better query performance
bookingSchema.index({ passengerId: 1 });
bookingSchema.index({ timetableId: 1 });
bookingSchema.index({ bookingReference: 1 });
bookingSchema.index({ bookingStatus: 1 });
bookingSchema.index({ journeyDate: 1 });
bookingSchema.index({ paymentStatus: 1 });
bookingSchema.index({ createdAt: -1 });

// Compound index for finding bookings by passenger and status
bookingSchema.index({ passengerId: 1, bookingStatus: 1 });

// Index for seat availability queries
bookingSchema.index({ timetableId: 1, journeyDate: 1, bookingStatus: 1 });

module.exports = mongoose.model('Booking', bookingSchema);

