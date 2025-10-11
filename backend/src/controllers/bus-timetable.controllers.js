const BusTimeTable = require('../models/bus-timetable.model');
const Notification = require('../models/notification.model');
const logger = require('../utils/logger');

// Get all timetables with optional filters
const getBusTimeTable = async (req, res, next) => {
  try {
    const { from, to, startTime, endTime, busType, page = 1, limit = 50, status } = req.query;
    
    // Build filter object
    const filter = { isActive: true };
    
    // Only show approved schedules for non-admin users
    if (!req.user || (req.user.role !== 'admin' && req.user.role !== 'super_admin')) {
      filter.status = 'approved';
    } else if (status) {
      filter.status = status;
    }
    
    if (from) {
      filter.from = { $regex: from, $options: 'i' };
    }
    
    if (to) {
      filter.to = { $regex: to, $options: 'i' };
    }
    
    if (startTime) {
      filter.startTime = { $gte: startTime };
    }
    
    if (endTime) {
      filter.endTime = { $lte: endTime };
    }
    
    if (busType) {
      filter.busType = busType;
    }

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    // Get timetables with pagination
    const timetables = await BusTimeTable.find(filter)
      .populate('createdBy', 'fullName name email')
      .populate('reviewedBy', 'name email')
      .sort({ createdAt: -1, startTime: 1 })
      .skip(skip)
      .limit(parseInt(limit));
    
    // Get total count for pagination
    const total = await BusTimeTable.countDocuments(filter);
    
    logger.info('Bus timetables retrieved successfully', {
      count: timetables.length,
      total,
      filters: filter
    });

    res.json({
      success: true,
      message: 'Bus timetables retrieved successfully',
      data: timetables,
      pagination: {
        current: parseInt(page),
        pages: Math.ceil(total / parseInt(limit)),
        total
      }
    });
  } catch (error) {
    logger.error('Error retrieving bus timetables', { error: error.message });
    next(error);
  }
};

// Create new timetable (Admin or Driver)
const createBusTimeTable = async (req, res, next) => {
  try {
    const { from, to, startTime, endTime, busType } = req.body;
    
    // Check for duplicate route with same time
    const existingTimetable = await BusTimeTable.findOne({
      from: { $regex: `^${from}$`, $options: 'i' },
      to: { $regex: `^${to}$`, $options: 'i' },
      startTime,
      isActive: true,
      status: { $in: ['approved', 'pending'] }
    });
    
    if (existingTimetable) {
      return res.status(400).json({
        success: false,
        message: 'A timetable already exists for this route and time'
      });
    }

    // Determine status based on user role
    const isAdmin = req.user.role === 'admin' || req.user.role === 'super_admin';
    const status = isAdmin ? 'approved' : 'pending';
    const createdByModel = isAdmin ? 'Admin' : 'Driver';

    const timetable = new BusTimeTable({
      from,
      to,
      startTime,
      endTime,
      busType,
      createdBy: req.user._id,
      createdByModel,
      status
    });

    await timetable.save();
    await timetable.populate('createdBy', 'fullName name email');

    logger.info('Bus timetable created successfully', {
      timetableId: timetable._id,
      createdBy: req.user._id,
      status
    });

    res.status(201).json({
      success: true,
      message: isAdmin 
        ? 'Bus timetable created successfully'
        : 'Bus timetable submitted for admin approval',
      data: timetable
    });
  } catch (error) {
    logger.error('Error creating bus timetable', { error: error.message });
    next(error);
  }
};

// Update timetable
const updateBusTimeTable = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { from, to, startTime, endTime, busType } = req.body;
    
    const timetable = await BusTimeTable.findById(id);
    if (!timetable) {
      return res.status(404).json({
        success: false,
        message: 'Bus timetable not found'
      });
    }

    const isAdmin = req.user.role === 'admin' || req.user.role === 'super_admin';
    
    // Check if driver is updating their own schedule
    if (!isAdmin && timetable.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'You can only edit your own schedules'
      });
    }

    // Check for duplicate route with same time (excluding current record)
    const existingTimetable = await BusTimeTable.findOne({
      _id: { $ne: id },
      from: { $regex: `^${from}$`, $options: 'i' },
      to: { $regex: `^${to}$`, $options: 'i' },
      startTime,
      isActive: true,
      status: { $in: ['approved', 'pending'] }
    });
    
    if (existingTimetable) {
      return res.status(400).json({
        success: false,
        message: 'A timetable already exists for this route and time'
      });
    }

    // Update fields
    timetable.from = from;
    timetable.to = to;
    timetable.startTime = startTime;
    timetable.endTime = endTime;
    timetable.busType = busType;

    // If driver is editing, set status to pending
    if (!isAdmin) {
      timetable.status = 'pending';
      timetable.rejectionReason = null;
    }

    await timetable.save();
    await timetable.populate('createdBy', 'fullName name email');

    logger.info('Bus timetable updated successfully', {
      timetableId: timetable._id,
      updatedBy: req.user._id
    });

    res.json({
      success: true,
      message: isAdmin
        ? 'Bus timetable updated successfully'
        : 'Schedule updated and submitted for admin approval',
      data: timetable
    });
  } catch (error) {
    logger.error('Error updating bus timetable', { error: error.message });
    next(error);
  }
};

// Delete timetable
const deleteBusTimeTable = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const timetable = await BusTimeTable.findById(id);
    if (!timetable) {
      return res.status(404).json({
        success: false,
        message: 'Bus timetable not found'
      });
    }

    const isAdmin = req.user.role === 'admin' || req.user.role === 'super_admin';
    
    // Check if driver is deleting their own schedule
    if (!isAdmin && timetable.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own schedules'
      });
    }

    // Soft delete
    timetable.isActive = false;
    await timetable.save();

    logger.info('Bus timetable deleted successfully', {
      timetableId: timetable._id,
      deletedBy: req.user._id
    });

    res.json({
      success: true,
      message: 'Bus timetable deleted successfully'
    });
  } catch (error) {
    logger.error('Error deleting bus timetable', { error: error.message });
    next(error);
  }
};

// Get single timetable
const getBusTimeTableById = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const timetable = await BusTimeTable.findOne({ _id: id, isActive: true })
      .populate('createdBy', 'fullName name email')
      .populate('reviewedBy', 'name email');
    
    if (!timetable) {
      return res.status(404).json({
        success: false,
        message: 'Bus timetable not found'
      });
    }

    res.json({
      success: true,
      message: 'Bus timetable retrieved successfully',
      data: timetable
    });
  } catch (error) {
    logger.error('Error retrieving bus timetable', { error: error.message });
    next(error);
  }
};

// Get driver's own schedules
const getDriverSchedules = async (req, res, next) => {
  try {
    const timetables = await BusTimeTable.find({
      createdBy: req.user._id,
      isActive: true
    })
      .populate('reviewedBy', 'name email')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      message: 'Driver schedules retrieved successfully',
      data: timetables
    });
  } catch (error) {
    logger.error('Error retrieving driver schedules', { error: error.message });
    next(error);
  }
};

// Admin: Approve schedule
const approveSchedule = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const timetable = await BusTimeTable.findById(id);
    if (!timetable) {
      return res.status(404).json({
        success: false,
        message: 'Bus timetable not found'
      });
    }

    timetable.status = 'approved';
    timetable.reviewedBy = req.user._id;
    timetable.reviewedAt = new Date();
    timetable.rejectionReason = null;

    await timetable.save();

    // Create notification for driver
    if (timetable.createdByModel === 'Driver') {
      await Notification.create({
        recipientId: timetable.createdBy,
        recipientModel: 'Driver',
        senderId: req.user._id,
        type: 'schedule_approved',
        title: 'Schedule Approved',
        message: `Your schedule from ${timetable.from} to ${timetable.to} (${timetable.startTime}) has been approved.`,
        relatedScheduleId: timetable._id
      });
    }

    logger.info('Schedule approved', {
      scheduleId: id,
      approvedBy: req.user._id
    });

    res.json({
      success: true,
      message: 'Schedule approved successfully',
      data: timetable
    });
  } catch (error) {
    logger.error('Error approving schedule', { error: error.message });
    next(error);
  }
};

// Admin: Reject schedule
const rejectSchedule = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    if (!reason || reason.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Rejection reason is required'
      });
    }

    const timetable = await BusTimeTable.findById(id);
    if (!timetable) {
      return res.status(404).json({
        success: false,
        message: 'Bus timetable not found'
      });
    }

    timetable.status = 'rejected';
    timetable.rejectionReason = reason;
    timetable.reviewedBy = req.user._id;
    timetable.reviewedAt = new Date();

    await timetable.save();

    // Create notification for driver
    if (timetable.createdByModel === 'Driver') {
      await Notification.create({
        recipientId: timetable.createdBy,
        recipientModel: 'Driver',
        senderId: req.user._id,
        type: 'schedule_rejected',
        title: 'Schedule Rejected',
        message: `Your schedule from ${timetable.from} to ${timetable.to} (${timetable.startTime}) was rejected. Reason: ${reason}`,
        relatedScheduleId: timetable._id
      });
    }

    logger.info('Schedule rejected', {
      scheduleId: id,
      rejectedBy: req.user._id,
      reason
    });

    res.json({
      success: true,
      message: 'Schedule rejected successfully',
      data: timetable
    });
  } catch (error) {
    logger.error('Error rejecting schedule', { error: error.message });
    next(error);
  }
};

module.exports = {
  getBusTimeTable,
  createBusTimeTable,
  updateBusTimeTable,
  deleteBusTimeTable,
  getBusTimeTableById,
  getDriverSchedules,
  approveSchedule,
  rejectSchedule
};