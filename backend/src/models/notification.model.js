const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  recipientId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    refPath: 'recipientModel'
  },
  recipientModel: {
    type: String,
    required: true,
    enum: ['Driver', 'Admin', 'Passenger', 'Connector']
  },
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin'
  },
  type: {
    type: String,
    required: true,
    enum: ['schedule_rejected', 'schedule_approved', 'general']
  },
  title: {
    type: String,
    required: true
  },
  message: {
    type: String,
    required: true
  },
  relatedScheduleId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'BusTimeTable'
  },
  isRead: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Notification', notificationSchema);