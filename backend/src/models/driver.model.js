const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const driverSchema = new mongoose.Schema({
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
    required: [true, 'Phone number is required'],
    trim: true,
    match: [/^0\d{9}$/, 'Please enter a valid Sri Lankan phone number']
  },
  licenseNumber: {
    type: String,
    required: [true, 'License number is required'],
    unique: true,
    trim: true,
    uppercase: true,
    match: [/^[A-Z]\d{7}$/, 'License number must be in format A1234567']
  },
  nicNumber: {
    type: String,
    required: [true, 'NIC number is required'],
    unique: true,
    trim: true,
    uppercase: true,
    match: [/^\d{9}[VX]$|^\d{12}$/, 'NIC number must be in format 123456789V or 123456789012']
  },
  busNumber: {
    type: String,
    required: [true, 'Bus number is required'],
    trim: true,
    uppercase: true,
    match: [/^[A-Z]{2}-\d{4}$/, 'Bus number must be in format AB-1234']
  },
  role: {
    type: String,
    default: 'driver',
    enum: ['driver']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  rejectionReason: {
    type: String,
    default: null
  },
  verificationStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  }
}, {
  timestamps: true
});

// Hash password before saving
driverSchema.pre('save', async function(next) {
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
driverSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Override toJSON to remove sensitive data
driverSchema.methods.toJSON = function() {
  const driver = this.toObject();
  delete driver.password;
  delete driver.__v;
  driver.id = driver._id;
  delete driver._id;
  return driver;
};

module.exports = mongoose.model('Driver', driverSchema);