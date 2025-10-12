const Notification = require('../models/notification.model');
const logger = require('../utils/logger');

// Get user's notifications
const getNotifications = async (req, res, next) => {
  try {
    const notifications = await Notification.find({
      recipientId: req.user._id
    })
      .populate('senderId', 'name email')
      .populate('relatedScheduleId')
      .sort({ createdAt: -1 })
      .limit(50);

    res.json({
      success: true,
      message: 'Notifications retrieved successfully',
      data: notifications
    });
  } catch (error) {
    logger.error('Error retrieving notifications', { error: error.message });
    next(error);
  }
};

// Mark notification as read
const markAsRead = async (req, res, next) => {
  try {
    const { id } = req.params;

    const notification = await Notification.findOneAndUpdate(
      { _id: id, recipientId: req.user._id },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.json({
      success: true,
      message: 'Notification marked as read',
      data: notification
    });
  } catch (error) {
    logger.error('Error marking notification as read', { error: error.message });
    next(error);
  }
};

// Get unread count
const getUnreadCount = async (req, res, next) => {
  try {
    const count = await Notification.countDocuments({
      recipientId: req.user._id,
      isRead: false
    });

    res.json({
      success: true,
      message: 'Unread count retrieved successfully',
      data: { count }
    });
  } catch (error) {
    logger.error('Error getting unread count', { error: error.message });
    next(error);
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  getUnreadCount
};