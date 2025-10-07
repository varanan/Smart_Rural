const express = require('express');
const {
  getBusTimeTable,
  createBusTimeTable,
  updateBusTimeTable,
  deleteBusTimeTable,
  getBusTimeTableById,
  getDriverSchedules,
  approveSchedule,
  rejectSchedule
} = require('../controllers/bus-timetable.controllers');
const { authenticate, authorize } = require('../middlewares/auth.middleware');
const { busTimeTableSchema, validate } = require('../controllers/validators/bus-timetable.validators');

const router = express.Router();

// Protected route - requires authentication to see pending schedules
router.get('/', authenticate, getBusTimeTable);
router.get('/:id', authenticate, getBusTimeTableById);

// Driver routes
router.get('/driver/my-schedules', authenticate, authorize('driver'), getDriverSchedules);
router.post('/driver/create', authenticate, authorize('driver'), validate(busTimeTableSchema), createBusTimeTable);
router.put('/driver/:id', authenticate, authorize('driver'), validate(busTimeTableSchema), updateBusTimeTable);
router.delete('/driver/:id', authenticate, authorize('driver'), deleteBusTimeTable);

// Admin routes
router.post('/', authenticate, authorize('admin', 'super_admin'), validate(busTimeTableSchema), createBusTimeTable);
router.put('/:id', authenticate, authorize('admin', 'super_admin'), validate(busTimeTableSchema), updateBusTimeTable);
router.delete('/:id', authenticate, authorize('admin', 'super_admin'), deleteBusTimeTable);
router.patch('/:id/approve', authenticate, authorize('admin', 'super_admin'), approveSchedule);
router.patch('/:id/reject', authenticate, authorize('admin', 'super_admin'), rejectSchedule);

module.exports = router;