const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const BusTimeTable = require('./src/models/bus-timetable.model');
const Booking = require('./src/models/booking.model');

const testBookingAPI = async () => {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/smart_rural');
    console.log('✅ Connected to MongoDB');

    // Test 1: Check if bus timetables have required fields
    console.log('\n📊 Testing Bus Timetables...');
    const buses = await BusTimeTable.find({ isActive: true }).limit(5);
    
    if (buses.length === 0) {
      console.log('❌ No active bus timetables found');
      return;
    }

    console.log(`✅ Found ${buses.length} active buses`);
    
    for (const bus of buses) {
      console.log(`🚌 Bus: ${bus.from} → ${bus.to}`);
      console.log(`   - ID: ${bus._id}`);
      console.log(`   - Type: ${bus.busType}`);
      console.log(`   - Total Seats: ${bus.totalSeats || 'MISSING'}`);
      console.log(`   - Fare: Rs. ${bus.fare || 'MISSING'}`);
      
      if (!bus.totalSeats || !bus.fare) {
        console.log('   ⚠️  Missing required fields for booking!');
      }
    }

    // Test 2: Test available seats logic
    console.log('\n🪑 Testing Available Seats Logic...');
    const testBus = buses[0];
    
    if (testBus.totalSeats && testBus.fare) {
      const testDate = new Date();
      testDate.setDate(testDate.getDate() + 1); // Tomorrow
      
      // Get booked seats for tomorrow
      const bookedSeats = await Booking.find({
        busId: testBus._id,
        travelDate: testDate,
        status: 'confirmed'
      }).select('seatNumber');

      const bookedSeatNumbers = bookedSeats.map(booking => booking.seatNumber);
      const availableSeats = [];

      for (let i = 1; i <= testBus.totalSeats; i++) {
        if (!bookedSeatNumbers.includes(i)) {
          availableSeats.push(i);
        }
      }

      console.log(`✅ Bus: ${testBus.from} → ${testBus.to}`);
      console.log(`   - Total Seats: ${testBus.totalSeats}`);
      console.log(`   - Booked Seats: [${bookedSeatNumbers.join(', ')}]`);
      console.log(`   - Available Seats: ${availableSeats.length} seats`);
      console.log(`   - Fare: Rs. ${testBus.fare}`);
    }

    // Test 3: Check existing bookings
    console.log('\n📋 Testing Existing Bookings...');
    const bookingCount = await Booking.countDocuments();
    console.log(`✅ Total bookings in database: ${bookingCount}`);

    if (bookingCount > 0) {
      const recentBookings = await Booking.find()
        .populate('busId', 'from to busType')
        .sort({ createdAt: -1 })
        .limit(3);

      console.log('Recent bookings:');
      for (const booking of recentBookings) {
        console.log(`   - Seat ${booking.seatNumber} on ${booking.busId?.from} → ${booking.busId?.to}`);
        console.log(`     Status: ${booking.status}, Date: ${booking.travelDate.toDateString()}`);
      }
    }

  } catch (error) {
    console.error('❌ Error testing booking API:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n📤 Disconnected from MongoDB');
    process.exit(0);
  }
};

// Run the test
testBookingAPI();
