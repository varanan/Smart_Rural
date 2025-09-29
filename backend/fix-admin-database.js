const mongoose = require('mongoose');
require('dotenv').config();

async function fixAdminDatabase() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Get the admins collection
    const db = mongoose.connection.db;
    const adminsCollection = db.collection('admins');

    // Check existing indexes
    const indexes = await adminsCollection.indexes();
    console.log('Current indexes:', indexes.map(idx => ({ name: idx.name, keys: idx.key, unique: idx.unique })));

    // Count existing admins
    const adminCount = await adminsCollection.countDocuments();
    console.log(`Total admins in database: ${adminCount}`);

    // List all admins (without passwords)
    const admins = await adminsCollection.find({}, { 
      projection: { password: 0 } 
    }).toArray();
    
    console.log('\nExisting admins:');
    admins.forEach((admin, index) => {
      console.log(`${index + 1}. Name: ${admin.name}, Email: ${admin.email}, Role: ${admin.role}, Active: ${admin.isActive}`);
    });

    // Check for duplicate emails (case-insensitive)
    const pipeline = [
      {
        $group: {
          _id: { $toLower: '$email' },
          count: { $sum: 1 },
          docs: { $push: '$$ROOT' }
        }
      },
      {
        $match: { count: { $gt: 1 } }
      }
    ];

    const duplicateEmails = await adminsCollection.aggregate(pipeline).toArray();

    if (duplicateEmails.length > 0) {
      console.log('\nFound duplicate emails (case-insensitive):');
      for (const group of duplicateEmails) {
        console.log(`Email: ${group._id}, Count: ${group.count}`);
        
        // Keep the first document, remove duplicates
        const docsToRemove = group.docs.slice(1);
        for (const doc of docsToRemove) {
          await adminsCollection.deleteOne({ _id: doc._id });
          console.log(`  Removed duplicate: ${doc.name} (${doc.email})`);
        }
      }
    } else {
      console.log('\nNo duplicate emails found.');
    }

    // Normalize all existing emails to lowercase
    const normalizeResult = await adminsCollection.updateMany(
      {},
      [
        {
          $set: {
            email: { $toLower: '$email' }
          }
        }
      ]
    );
    console.log(`\nNormalized ${normalizeResult.modifiedCount} email addresses to lowercase.`);

    console.log('\nAdmin database cleanup completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error fixing admin database:', error);
    process.exit(1);
  }
}

fixAdminDatabase();
