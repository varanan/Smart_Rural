const mongoose = require('mongoose');

const busTimeTableSchema = new mongoose.Schema({
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
  endTime: {
    type: String,
    required: [true, 'End time is required'],
    trim: true
  },
  busType: {
    type: String,
    required: [true, 'Bus type is required'],
    enum: ['Normal', 'Express', 'Luxury', 'Semi-Luxury', 'Intercity'],
    default: 'Normal'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    refPath: 'createdByModel'
  },
  createdByModel: {
    type: String,
    enum: ['Admin', 'Driver'],
    default: 'Admin'
  },
  status: {
    type: String,
    enum: ['approved', 'pending', 'rejected'],
    default: 'approved'
  },
  rejectionReason: {
    type: String,
    default: null
  },
  reviewedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin'
  },
  reviewedAt: {
    type: Date
  }
}, {
  timestamps: true
});

// Create indexes for better query performance
busTimeTableSchema.index({ from: 1, to: 1 });
busTimeTableSchema.index({ startTime: 1 });
busTimeTableSchema.index({ busType: 1 });
busTimeTableSchema.index({ isActive: 1 });
busTimeTableSchema.index({ status: 1 });
busTimeTableSchema.index({ createdBy: 1 });

module.exports = mongoose.model('BusTimeTable', busTimeTableSchema);