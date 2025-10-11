const mongoose = require('mongoose');
require('dotenv').config();

async function resetAdminDatabase() {
  try {
    console.log('Starting admin database reset...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Get the database and collection
    const db = mongoose.connection.db;
    const adminsCollection = db.collection('admins');

    // Show current state
    const currentAdmins = await adminsCollection.find({}, { 
      projection: { password: 0 } 
    }).toArray();
    
    console.log(`\nCurrent admins in database: ${currentAdmins.length}`);
    currentAdmins.forEach((admin, index) => {
      console.log(`   ${index + 1}. ${admin.name} - ${admin.email} (${admin.role})`);
    });

    // Ask for confirmation
    console.log('\nWARNING: This will DELETE ALL admin accounts!');
    console.log('You can create new admins after this reset.');
    
    // Drop the entire admins collection
    try {
      await adminsCollection.drop();
      console.log('Dropped admins collection');
    } catch (error) {
      if (error.code === 26) {
        console.log('Admins collection was already empty');
      } else {
        throw error;
      }
    }

    // Recreate the collection with proper indexes
    await db.createCollection('admins');
    console.log('Recreated admins collection');

    // Create the unique email index
    await adminsCollection.createIndex(
      { email: 1 }, 
      { unique: true, name: 'email_unique' }
    );
    console.log('Created unique email index');

    // Verify the collection is empty
    const count = await adminsCollection.countDocuments();
    console.log(`\nReset complete! Admin collection now has ${count} documents`);
    
    console.log('\nYou can now create multiple admin accounts!');
    console.log('Try creating admins with different email addresses.');
    
    process.exit(0);
  } catch (error) {
    console.error('Error resetting admin database:', error);
    process.exit(1);
  }
}

resetAdminDatabase();
