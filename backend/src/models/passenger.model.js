const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const passengerSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: [true, 'Full name is required'],
    trim: true,
    minlength: [2, 'Full name must be at least 2 characters'],
    maxlength: [100, 'Full name cannot exceed 100 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [8, 'Password must be at least 8 characters']
  },
  phone: {
    type: String,
    required: false,
    trim: true,
    match: [/^0\d{9}$/, 'Please enter a valid Sri Lankan phone number']
  },
  role: {
    type: String,
    default: 'passenger',
    enum: ['passenger']
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Hash password before saving
passengerSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const saltRounds = 10;
    this.password = await bcrypt.hash(this.password, saltRounds);
    next();
  } catch (error) {
    next(error);
  }
});

// Instance method to compare password
passengerSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Override toJSON to remove sensitive data
passengerSchema.methods.toJSON = function() {
  const passenger = this.toObject();
  delete passenger.password;
  delete passenger.__v;
  passenger.id = passenger._id;
  delete passenger._id;
  return passenger;
};

module.exports = mongoose.model('Passenger', passengerSchema);
