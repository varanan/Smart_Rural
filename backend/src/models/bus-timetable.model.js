const mongoose = require('mongoose');

const busTimeTableSchema = new mongoose.Schema({
  from: {
    type: String,
    required: [true, 'From location is required'],
    trim: true,
    uppercase: true
  },
  to: {
    type: String,
    required: [true, 'To location is required'],
    trim: true,
    uppercase: true
  },
  route: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Route',
    required: false // Optional for backward compatibility
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
    ref: 'Admin',
    required: true
  }
}, {
  timestamps: true
});

// Auto-link route before saving
busTimeTableSchema.pre('save', async function(next) {
  if (!this.route && this.from && this.to) {
    try {
      const Route = mongoose.model('Route');
      const route = await Route.findOne({
        from: this.from.toUpperCase(),
        to: this.to.toUpperCase(),
        isActive: true
      });
      
      if (route) {
        this.route = route._id;
      }
    } catch (error) {
      // Continue without route if not found
    }
  }
  next();
});

// Create indexes for better query performance
busTimeTableSchema.index({ from: 1, to: 1 });
busTimeTableSchema.index({ startTime: 1 });
busTimeTableSchema.index({ busType: 1 });
busTimeTableSchema.index({ isActive: 1 });
busTimeTableSchema.index({ route: 1 });

module.exports = mongoose.model('BusTimeTable', busTimeTableSchema);
