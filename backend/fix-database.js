const mongoose = require('mongoose');
require('dotenv').config();

async function fixDatabase() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Get the passengers collection
    const db = mongoose.connection.db;
    const passengersCollection = db.collection('passengers');

    // Remove any nicNumber field from existing documents
    const result = await passengersCollection.updateMany(
      { nicNumber: { $exists: true } },
      { $unset: { nicNumber: 1 } }
    );
    console.log(`Removed nicNumber field from ${result.modifiedCount} documents`);

    // Try to drop the nicNumber index if it exists
    try {
      await passengersCollection.dropIndex('nicNumber_1');
      console.log('Dropped nicNumber_1 index');
    } catch (error) {
      console.log('nicNumber_1 index not found or already dropped');
    }

    console.log('Database cleanup completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error fixing database:', error);
    process.exit(1);
  }
}

fixDatabase();
