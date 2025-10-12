const mongoose = require('mongoose');

const rideShareSchema = new mongoose.Schema({
  from: {
    type: String,
    required: [true, 'From location is required'],
    trim: true
  },
  to: {
    type: String,
    required: [true, 'To location is required'],
    trim: true
  },
  startTime: {
    type: String,
    required: [true, 'Start time is required'],
    trim: true
  },
  vehicleType: {
    type: String,
    required: [true, 'Vehicle type is required'],
    enum: ['Car', 'Motorbike'],
    default: 'Car'
  },
  seatCapacity: {
    type: Number,
    required: [true, 'Seat capacity is required'],
    min: [1, 'Minimum seat capacity should be 1']
  },
  price: {
    type: Number,
    required: [true, 'Price is required'],
    min: [0, 'Price cannot be negative']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Connector',
    required: true
  },
  requests: [{
    passenger: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Passenger',
      required: true
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'rejected'],
      default: 'pending'
    },
    requestedAt: {
      type: Date,
      default: Date.now
    }
  }],
  availableSeats: {
    type: Number,
    required: true
  },
  message: {
    type: String,
    default: '',
    trim: true,
    maxLength: [500, 'Message cannot exceed 500 characters']
  }
}, {
  timestamps: true
});

// Create indexes for better query performance
rideShareSchema.index({ from: 1, to: 1 });
rideShareSchema.index({ startTime: 1 });
rideShareSchema.index({ vehicleType: 1 });
rideShareSchema.index({ isActive: 1 });
rideShareSchema.index({ createdBy: 1 });
rideShareSchema.index({ 'requests.passenger': 1 });
rideShareSchema.index({ 'requests.status': 1 });

// Pre-save middleware to ensure availableSeats matches seatCapacity on creation
rideShareSchema.pre('save', function(next) {
  if (this.isNew) {
    this.availableSeats = this.seatCapacity;
  }
  next();
});

module.exports = mongoose.model('RideShare', rideShareSchema);