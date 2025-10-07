const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const BusTimeTable = require('./src/models/bus-timetable.model');
const Booking = require('./src/models/booking.model');

const debugAndFixBooking = async () => {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/smart_rural');
    console.log('✅ Connected to MongoDB');

    console.log('\n🔍 STEP 1: Checking Bus Timetables...');
    
    // Get all bus timetables
    const allBuses = await BusTimeTable.find();
    console.log(`📊 Total bus timetables in database: ${allBuses.length}`);
    
    const activeBuses = await BusTimeTable.find({ isActive: true });
    console.log(`✅ Active bus timetables: ${activeBuses.length}`);

    if (activeBuses.length === 0) {
      console.log('❌ No active bus timetables found! Creating sample data...');
      
      // Create sample bus timetables
      const sampleBuses = [
        {
          from: 'Colombo',
          to: 'Kandy',
          startTime: '08:00',
          endTime: '11:00',
          busType: 'Express',
          totalSeats: 35,
          fare: 80,
          isActive: true,
          createdBy: new mongoose.Types.ObjectId()
        },
        {
          from: 'Kandy',
          to: 'Galle',
          startTime: '09:30',
          endTime: '13:00',
          busType: 'Luxury',
          totalSeats: 25,
          fare: 150,
          isActive: true,
          createdBy: new mongoose.Types.ObjectId()
        },
        {
          from: 'Colombo',
          to: 'Matara',
          startTime: '06:00',
          endTime: '10:30',
          busType: 'Normal',
          totalSeats: 30,
          fare: 50,
          isActive: true,
          createdBy: new mongoose.Types.ObjectId()
        }
      ];

      await BusTimeTable.insertMany(sampleBuses);
      console.log('✅ Created sample bus timetables');
      
      // Refresh the active buses list
      const newActiveBuses = await BusTimeTable.find({ isActive: true });
      console.log(`✅ Now have ${newActiveBuses.length} active buses`);
    }

    console.log('\n🔍 STEP 2: Checking Required Fields...');
    
    // Check for missing fields
    const busesWithoutSeats = await BusTimeTable.find({
      isActive: true,
      $or: [
        { totalSeats: { $exists: false } },
        { totalSeats: null },
        { totalSeats: 0 }
      ]
    });

    const busesWithoutFare = await BusTimeTable.find({
      isActive: true,
      $or: [
        { fare: { $exists: false } },
        { fare: null },
        { fare: 0 }
      ]
    });

    console.log(`⚠️  Buses without totalSeats: ${busesWithoutSeats.length}`);
    console.log(`⚠️  Buses without fare: ${busesWithoutFare.length}`);

    // Fix missing fields
    if (busesWithoutSeats.length > 0 || busesWithoutFare.length > 0) {
      console.log('\n🔧 STEP 3: Fixing Missing Fields...');
      
      const allActiveBuses = await BusTimeTable.find({ isActive: true });
      
      for (const bus of allActiveBuses) {
        let needsUpdate = false;
        const updateData = {};

        if (!bus.totalSeats || bus.totalSeats === 0) {
          let defaultSeats = 30;
          switch (bus.busType) {
            case 'Luxury': defaultSeats = 25; break;
            case 'Semi-Luxury': defaultSeats = 28; break;
            case 'Express': defaultSeats = 35; break;
            case 'Intercity': defaultSeats = 40; break;
            default: defaultSeats = 30;
          }
          updateData.totalSeats = defaultSeats;
          needsUpdate = true;
        }

        if (!bus.fare || bus.fare === 0) {
          let defaultFare = 50;
          switch (bus.busType) {
            case 'Luxury': defaultFare = 150; break;
            case 'Semi-Luxury': defaultFare = 100; break;
            case 'Express': defaultFare = 80; break;
            case 'Intercity': defaultFare = 120; break;
            default: defaultFare = 50;
          }
          updateData.fare = defaultFare;
          needsUpdate = true;
        }

        if (needsUpdate) {
          await BusTimeTable.findByIdAndUpdate(bus._id, { $set: updateData });
          console.log(`✅ Updated ${bus.from} → ${bus.to}: seats=${updateData.totalSeats || bus.totalSeats}, fare=${updateData.fare || bus.fare}`);
        }
      }
    }

    console.log('\n🔍 STEP 4: Final Verification...');
    
    const finalBuses = await BusTimeTable.find({ isActive: true });
    console.log(`✅ Total active buses: ${finalBuses.length}`);
    
    for (const bus of finalBuses.slice(0, 5)) { // Show first 5
      console.log(`🚌 ${bus.from} → ${bus.to}`);
      console.log(`   ID: ${bus._id}`);
      console.log(`   Type: ${bus.busType}`);
      console.log(`   Seats: ${bus.totalSeats}`);
      console.log(`   Fare: Rs. ${bus.fare}`);
      console.log(`   Active: ${bus.isActive}`);
      console.log('');
    }

    console.log('\n🧪 STEP 5: Testing Available Seats API Logic...');
    
    if (finalBuses.length > 0) {
      const testBus = finalBuses[0];
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);

      console.log(`Testing with bus: ${testBus.from} → ${testBus.to}`);
      console.log(`Bus ID: ${testBus._id}`);
      console.log(`Travel Date: ${tomorrow.toISOString()}`);

      // Simulate the API logic
      const bookedSeats = await Booking.find({
        busId: testBus._id,
        travelDate: {
          $gte: tomorrow,
          $lt: new Date(tomorrow.getTime() + 24 * 60 * 60 * 1000)
        },
        status: 'confirmed'
      }).select('seatNumber');

      const bookedSeatNumbers = bookedSeats.map(booking => booking.seatNumber);
      const availableSeats = [];

      for (let i = 1; i <= testBus.totalSeats; i++) {
        if (!bookedSeatNumbers.includes(i)) {
          availableSeats.push(i);
        }
      }

      console.log(`✅ API Test Results:`);
      console.log(`   Total Seats: ${testBus.totalSeats}`);
      console.log(`   Booked Seats: [${bookedSeatNumbers.join(', ') || 'None'}]`);
      console.log(`   Available Seats: ${availableSeats.length} (${availableSeats.slice(0, 10).join(', ')}${availableSeats.length > 10 ? '...' : ''})`);
      console.log(`   Fare: Rs. ${testBus.fare}`);
    }

    console.log('\n🎉 Database is ready for booking!');
    console.log('\n📋 Next Steps:');
    console.log('1. Make sure your backend server is running on port 3000');
    console.log('2. Test the booking API endpoints');
    console.log('3. Check the frontend API calls');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n📤 Disconnected from MongoDB');
    process.exit(0);
  }
};

// Run the debug and fix
debugAndFixBooking();
