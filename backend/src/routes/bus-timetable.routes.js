const express = require('express');
const {
  getBusTimeTable,
  createBusTimeTable,
  updateBusTimeTable,
  deleteBusTimeTable,
  getBusTimeTableById
} = require('../controllers/bus-timetable.controllers');
const { authenticate, authorize } = require('../middlewares/auth.middleware');
const { busTimeTableSchema, validate } = require('../controllers/validators/bus-timetable.validators');

const router = express.Router();

// Public routes (anyone can view timetables)
router.get('/', getBusTimeTable);
router.get('/:id', getBusTimeTableById);

// Protected routes (Admin only)
router.post('/', authenticate, authorize('admin', 'super_admin'), validate(busTimeTableSchema), createBusTimeTable);
router.put('/:id', authenticate, authorize('admin', 'super_admin'), validate(busTimeTableSchema), updateBusTimeTable);
router.delete('/:id', authenticate, authorize('admin', 'super_admin'), deleteBusTimeTable);

module.exports = router;
