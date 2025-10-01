const BusTimeTable = require('../models/bus-timetable.model');
const logger = require('../utils/logger');

// Get all timetables with optional filters
const getBusTimeTable = async (req, res, next) => {
  try {
    const { from, to, startTime, endTime, busType, page = 1, limit = 50 } = req.query;
    
    // Build filter object
    const filter = { isActive: true };
    
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
      .populate('createdBy', 'name email')
      .sort({ startTime: 1, from: 1 })
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

// Create new timetable (Admin only)
const createBusTimeTable = async (req, res, next) => {
  try {
    const { from, to, startTime, endTime, busType } = req.body;
    
    // Check for duplicate route with same time
    const existingTimetable = await BusTimeTable.findOne({
      from: { $regex: `^${from}$`, $options: 'i' },
      to: { $regex: `^${to}$`, $options: 'i' },
      startTime,
      isActive: true
    });
    
    if (existingTimetable) {
      return res.status(400).json({
        success: false,
        message: 'A timetable already exists for this route and time'
      });
    }

    const timetable = new BusTimeTable({
      from,
      to,
      startTime,
      endTime,
      busType,
      createdBy: req.user._id
    });

    await timetable.save();
    await timetable.populate('createdBy', 'name email');

    logger.info('Bus timetable created successfully', {
      timetableId: timetable._id,
      createdBy: req.user._id
    });

    res.status(201).json({
      success: true,
      message: 'Bus timetable created successfully',
      data: timetable
    });
  } catch (error) {
    logger.error('Error creating bus timetable', { error: error.message });
    next(error);
  }
};

// Update timetable (Admin only)
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

    // Check for duplicate route with same time (excluding current record)
    const existingTimetable = await BusTimeTable.findOne({
      _id: { $ne: id },
      from: { $regex: `^${from}$`, $options: 'i' },
      to: { $regex: `^${to}$`, $options: 'i' },
      startTime,
      isActive: true
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

    await timetable.save();
    await timetable.populate('createdBy', 'name email');

    logger.info('Bus timetable updated successfully', {
      timetableId: timetable._id,
      updatedBy: req.user._id
    });

    res.json({
      success: true,
      message: 'Bus timetable updated successfully',
      data: timetable
    });
  } catch (error) {
    logger.error('Error updating bus timetable', { error: error.message });
    next(error);
  }
};

// Delete timetable (Admin only)
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
      .populate('createdBy', 'name email');
    
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

module.exports = {
  getBusTimeTable,
  createBusTimeTable,
  updateBusTimeTable,
  deleteBusTimeTable,
  getBusTimeTableById
};


