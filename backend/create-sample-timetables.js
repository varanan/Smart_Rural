require('dotenv').config();
const mongoose = require('mongoose');
const BusTimeTable = require('./src/models/bus-timetable.model');
const Admin = require('./src/models/admin.model');
const { connectDB } = require('./src/config/db');

const sampleTimetables = [
  {
    from: 'Colombo',
    to: 'Kandy',
    startTime: '06:00',
    endTime: '09:00',
    busType: 'Express'
  },
  {
    from: 'Colombo',
    to: 'Kandy',
    startTime: '08:30',
    endTime: '11:30',
    busType: 'Luxury'
  },
  {
    from: 'Kandy',
    to: 'Colombo',
    startTime: '07:00',
    endTime: '10:00',
    busType: 'Express'
  },
  {
    from: 'Colombo',
    to: 'Galle',
    startTime: '05:30',
    endTime: '08:00',
    busType: 'Normal'
  },
  {
    from: 'Colombo',
    to: 'Galle',
    startTime: '14:00',
    endTime: '16:30',
    busType: 'Semi-Luxury'
  },
  {
    from: 'Galle',
    to: 'Colombo',
    startTime: '06:30',
    endTime: '09:00',
    busType: 'Express'
  },
  {
    from: 'Colombo',
    to: 'Matara',
    startTime: '07:30',
    endTime: '10:30',
    busType: 'Intercity'
  },
  {
    from: 'Matara',
    to: 'Colombo',
    startTime: '15:00',
    endTime: '18:00',
    busType: 'Express'
  },
  {
    from: 'Kandy',
    to: 'Anuradhapura',
    startTime: '09:00',
    endTime: '12:00',
    busType: 'Normal'
  },
  {
    from: 'Anuradhapura',
    to: 'Kandy',
    startTime: '13:30',
    endTime: '16:30',
    busType: 'Express'
  }
];

const createSampleTimetables = async () => {
  try {
    await connectDB();
    
    // Find the first admin user to assign as creator
    const admin = await Admin.findOne({ isActive: true });
    if (!admin) {
      console.log('❌ No admin user found. Please create an admin user first.');
      process.exit(1);
    }

    // Clear existing timetables
    await BusTimeTable.deleteMany({});
    console.log('🗑️  Cleared existing timetables');

    // Create sample timetables
    const timetables = sampleTimetables.map(timetable => ({
      ...timetable,
      createdBy: admin._id
    }));

    await BusTimeTable.insertMany(timetables);
    console.log(`✅ Created ${timetables.length} sample bus timetables`);

    // Display created timetables
    const createdTimetables = await BusTimeTable.find({}).populate('createdBy', 'name');
    createdTimetables.forEach(timetable => {
      console.log(`📍 ${timetable.from} → ${timetable.to} | ${timetable.startTime}-${timetable.endTime} | ${timetable.busType}`);
    });

    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating sample timetables:', error);
    process.exit(1);
  }
};

createSampleTimetables();
