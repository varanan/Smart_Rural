const express = require('express');
const {
  getNotifications,
  markAsRead,
  getUnreadCount
} = require('../controllers/notification.controllers');
const { authenticate } = require('../middlewares/auth.middleware');

const router = express.Router();

router.get('/', authenticate, getNotifications);
router.get('/unread-count', authenticate, getUnreadCount);
router.patch('/:id/read', authenticate, markAsRead);

module.exports = router;