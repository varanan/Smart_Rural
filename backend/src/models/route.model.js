const mongoose = require('mongoose');

const routeSchema = new mongoose.Schema({
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
  distance: {
    type: Number,
    required: [true, 'Distance in kilometers is required'],
    min: [1, 'Distance must be at least 1 km']
  },
  basePricePerKm: {
    type: Number,
    required: [true, 'Base price per kilometer is required'],
    min: [0, 'Base price cannot be negative'],
    default: 8.0 // LKR per km base rate
  },
  routeCode: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    uppercase: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  description: {
    type: String,
    trim: true
  },
  // Additional pricing modifiers
  pricingModifiers: {
    peakHourMultiplier: {
      type: Number,
      default: 1.2,
      min: 1.0
    },
    weekendMultiplier: {
      type: Number,
      default: 1.1,
      min: 1.0
    },
    holidayMultiplier: {
      type: Number,
      default: 1.3,
      min: 1.0
    }
  },
  // Route-specific bus type multipliers (override global ones)
  busTypeMultipliers: {
    Normal: {
      type: Number,
      default: 1.0,
      min: 0.1
    },
    Express: {
      type: Number,
      default: 1.3,
      min: 0.1
    },
    Semi_Luxury: {
      type: Number,
      default: 1.5,
      min: 0.1
    },
    Luxury: {
      type: Number,
      default: 2.0,
      min: 0.1
    },
    Intercity: {
      type: Number,
      default: 1.2,
      min: 0.1
    }
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  }
}, {
  timestamps: true
});

// Generate route code before saving
routeSchema.pre('save', function(next) {
  if (this.isNew && !this.routeCode) {
    this.routeCode = `${this.from}-${this.to}`.replace(/\s+/g, '');
  }
  next();
});

// Create indexes for better query performance
routeSchema.index({ from: 1, to: 1 });
routeSchema.index({ routeCode: 1 });
routeSchema.index({ isActive: 1 });
routeSchema.index({ distance: 1 });

// Compound index for finding routes by from and to
routeSchema.index({ from: 1, to: 1, isActive: 1 });

// Virtual for calculating base price
routeSchema.virtual('basePrice').get(function() {
  return Math.round(this.distance * this.basePricePerKm);
});

// Ensure virtual fields are serialized
routeSchema.set('toJSON', { virtuals: true });
routeSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Route', routeSchema);
