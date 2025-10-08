const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const connectorSchema = new mongoose.Schema({
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
  licenseNumber: {
    type: String,
    required: [true, 'License number is required'],
    unique: true,
    trim: true,
    uppercase: true
  },
  nicNumber: {
    type: String,
    required: [true, 'NIC number is required'],
    unique: true,
    trim: true,
    uppercase: true,
  },
  vehicleNumber: {
    type: String,
    required: [true, 'Vehicle number is required'],
    unique: true,
    trim: true,
    uppercase: true,
  },
  role: {
    type: String,
    default: 'connector',
    enum: ['connector']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isVerified: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

// Hash password before saving
connectorSchema.pre('save', async function(next) {
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
connectorSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Remove sensitive fields
connectorSchema.methods.toJSON = function() {
  const connector = this.toObject();
  delete connector.password;
  delete connector.__v;
  connector.id = connector._id;
  delete connector._id;
  return connector;
};

module.exports = mongoose.model('Connector', connectorSchema);