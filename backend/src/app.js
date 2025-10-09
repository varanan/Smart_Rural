require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { connectDB } = require('./config/db');
const errorHandler = require('./middlewares/error.middleware');
const logger = require('./utils/logger');

// Route imports
const connectorRoutes = require('./routes/connector.routes');
const driverRoutes = require('./routes/driver.routes');
const passengerRoutes = require('./routes/passenger.routes');
const authRoutes = require('./routes/auth.routes');
const adminRoutes = require('./routes/admin.routes');
const busTimeTableRoutes = require('./routes/bus-timetable.routes');
const rideShareRoutes = require('./routes/ride-share.routes');

const app = express();

// -------------------------
// Middleware
// -------------------------
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// -------------------------
// Health check
// -------------------------
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

// -------------------------
// Routes
// -------------------------
app.use('/api/connector', connectorRoutes);
app.use('/api/drivers', driverRoutes);
app.use('/api/passenger', passengerRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/bus-timetable', busTimeTableRoutes);
app.use('/api/ride-share', rideShareRoutes);

// -------------------------
// Error handling middleware (must be last)
// -------------------------
app.use(errorHandler);

// -------------------------
// 404 Handler (Fallback)
// -------------------------
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// -------------------------
// Server start
// -------------------------
const startServer = async () => {
  try {
    await connectDB();
    const port = process.env.PORT || 3000;
    app.listen(port, () => {
      logger.info(`🚀 Server running on port ${port}`);
    });
  } catch (error) {
    logger.error('❌ Failed to start server', { error: error.message });
    process.exit(1);
  }
};

module.exports = { app, startServer };
