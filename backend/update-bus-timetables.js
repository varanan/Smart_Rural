const mongoose = require('mongoose');
require('dotenv').config();

// Import the updated model
const BusTimeTable = require('./src/models/bus-timetable.model');

const updateBusTimetables = async () => {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/smart_rural');
    console.log('✅ Connected to MongoDB');

    // Find all bus timetables that don't have totalSeats or fare fields
    const timetables = await BusTimeTable.find({
      $or: [
        { totalSeats: { $exists: false } },
        { fare: { $exists: false } }
      ]
    });

    console.log(`📊 Found ${timetables.length} timetables to update`);

    if (timetables.length === 0) {
      console.log('✅ All timetables already have the required fields');
      process.exit(0);
    }

    // Update each timetable with default values
    for (const timetable of timetables) {
      // Set default values based on bus type
      let defaultSeats = 30;
      let defaultFare = 50;

      switch (timetable.busType) {
        case 'Luxury':
          defaultSeats = 25;
          defaultFare = 150;
          break;
        case 'Semi-Luxury':
          defaultSeats = 28;
          defaultFare = 100;
          break;
        case 'Express':
          defaultSeats = 35;
          defaultFare = 80;
          break;
        case 'Intercity':
          defaultSeats = 40;
          defaultFare = 120;
          break;
        default: // Normal
          defaultSeats = 30;
          defaultFare = 50;
      }

      // Update the timetable
      await BusTimeTable.findByIdAndUpdate(
        timetable._id,
        {
          $set: {
            totalSeats: timetable.totalSeats || defaultSeats,
            fare: timetable.fare || defaultFare
          }
        }
      );

      console.log(`✅ Updated timetable: ${timetable.from} → ${timetable.to} (${timetable.busType})`);
    }

    console.log('🎉 All timetables updated successfully!');

    // Verify the updates
    const updatedCount = await BusTimeTable.countDocuments({
      totalSeats: { $exists: true },
      fare: { $exists: true }
    });

    console.log(`✅ Verified: ${updatedCount} timetables now have all required fields`);

  } catch (error) {
    console.error('❌ Error updating timetables:', error);
  } finally {
    await mongoose.disconnect();
    console.log('📤 Disconnected from MongoDB');
    process.exit(0);
  }
};

// Run the update
updateBusTimetables();
