const mongoose = require('mongoose');
require('dotenv').config();

const Route = require('./src/models/route.model');
const Admin = require('./src/models/admin.model');

// Popular Sri Lankan bus routes with actual distances
const popularRoutes = [
  // From Colombo
  { from: 'COLOMBO', to: 'KANDY', distance: 116, description: 'Colombo to Kandy via A1 highway' },
  { from: 'COLOMBO', to: 'GALLE', distance: 116, description: 'Colombo to Galle via Southern Expressway' },
  { from: 'COLOMBO', to: 'MATARA', distance: 160, description: 'Colombo to Matara via Southern Expressway' },
  { from: 'COLOMBO', to: 'ANURADHAPURA', distance: 205, description: 'Colombo to Anuradhapura via A9 highway' },
  { from: 'COLOMBO', to: 'JAFFNA', distance: 396, description: 'Colombo to Jaffna via A9 highway' },
  { from: 'COLOMBO', to: 'TRINCOMALEE', distance: 257, description: 'Colombo to Trincomalee via A6 highway' },
  { from: 'COLOMBO', to: 'BATTICALOA', distance: 314, description: 'Colombo to Batticaloa via A4 highway' },
  { from: 'COLOMBO', to: 'RATNAPURA', distance: 101, description: 'Colombo to Ratnapura via A4 highway' },
  { from: 'COLOMBO', to: 'KURUNEGALA', distance: 94, description: 'Colombo to Kurunegala via A1 highway' },
  { from: 'COLOMBO', to: 'CHILAW', distance: 80, description: 'Colombo to Chilaw via A3 highway' },
  { from: 'COLOMBO', to: 'PUTTALAM', distance: 130, description: 'Colombo to Puttalam via A3 highway' },
  { from: 'COLOMBO', to: 'NEGOMBO', distance: 37, description: 'Colombo to Negombo via A3 highway' },
  
  // From Kandy
  { from: 'KANDY', to: 'ANURADHAPURA', distance: 92, description: 'Kandy to Anuradhapura via A9 highway' },
  { from: 'KANDY', to: 'JAFFNA', distance: 280, description: 'Kandy to Jaffna via A9 highway' },
  { from: 'KANDY', to: 'TRINCOMALEE', distance: 141, description: 'Kandy to Trincomalee via A6 highway' },
  { from: 'KANDY', to: 'RATNAPURA', distance: 85, description: 'Kandy to Ratnapura via A4 highway' },
  { from: 'KANDY', to: 'BADULLA', distance: 78, description: 'Kandy to Badulla via A5 highway' },
  { from: 'KANDY', to: 'NUWARA ELIYA', distance: 75, description: 'Kandy to Nuwara Eliya via A5 highway' },
  { from: 'KANDY', to: 'KURUNEGALA', distance: 22, description: 'Kandy to Kurunegala via A1 highway' },
  
  // From Galle
  { from: 'GALLE', to: 'MATARA', distance: 44, description: 'Galle to Matara via Southern highway' },
  { from: 'GALLE', to: 'HAMBANTOTA', distance: 84, description: 'Galle to Hambantota via Southern highway' },
  { from: 'GALLE', to: 'RATNAPURA', distance: 115, description: 'Galle to Ratnapura via A4 highway' },
  
  // From Matara
  { from: 'MATARA', to: 'HAMBANTOTA', distance: 40, description: 'Matara to Hambantota via Southern highway' },
  { from: 'MATARA', to: 'TISSAMAHARAMA', distance: 54, description: 'Matara to Tissamaharama via Southern highway' },
  
  // From Kurunegala
  { from: 'KURUNEGALA', to: 'ANURADHAPURA', distance: 70, description: 'Kurunegala to Anuradhapura via A9 highway' },
  { from: 'KURUNEGALA', to: 'PUTTALAM', distance: 36, description: 'Kurunegala to Puttalam via A3 highway' },
  
  // From Anuradhapura
  { from: 'ANURADHAPURA', to: 'JAFFNA', distance: 191, description: 'Anuradhapura to Jaffna via A9 highway' },
  { from: 'ANURADHAPURA', to: 'TRINCOMALEE', distance: 52, description: 'Anuradhapura to Trincomalee via A6 highway' },
  
  // From Trincomalee
  { from: 'TRINCOMALEE', to: 'BATTICALOA', distance: 57, description: 'Trincomalee to Batticaloa via A4 highway' },
  
  // From Batticaloa
  { from: 'BATTICALOA', to: 'MONARAGALA', distance: 85, description: 'Batticaloa to Monaragala via A4 highway' },
  
  // From Ratnapura
  { from: 'RATNAPURA', to: 'BADULLA', distance: 95, description: 'Ratnapura to Badulla via A4 highway' },
  { from: 'RATNAPURA', to: 'EMBILIPITIYA', distance: 35, description: 'Ratnapura to Embilipitiya via local roads' },
  
  // From Badulla
  { from: 'BADULLA', to: 'NUWARA ELIYA', distance: 45, description: 'Badulla to Nuwara Eliya via A5 highway' },
  { from: 'BADULLA', to: 'MONARAGALA', distance: 65, description: 'Badulla to Monaragala via A4 highway' },
  
  // From Nuwara Eliya
  { from: 'NUWARA ELIYA', to: 'HATTON', distance: 25, description: 'Nuwara Eliya to Hatton via A5 highway' },
  
  // From Hatton
  { from: 'HATTON', to: 'COLOMBO', distance: 180, description: 'Hatton to Colombo via A1 highway' },
  
  // From Puttalam
  { from: 'PUTTALAM', to: 'CHILAW', distance: 50, description: 'Puttalam to Chilaw via A3 highway' },
  { from: 'PUTTALAM', to: 'NEGOMBO', distance: 80, description: 'Puttalam to Negombo via A3 highway' },
  
  // From Negombo
  { from: 'NEGOMBO', to: 'CHILAW', distance: 43, description: 'Negombo to Chilaw via A3 highway' },
  
  // From Hambantota
  { from: 'HAMBANTOTA', to: 'TISSAMAHARAMA', distance: 14, description: 'Hambantota to Tissamaharama via local roads' },
  { from: 'HAMBANTOTA', to: 'MONARAGALA', distance: 95, description: 'Hambantota to Monaragala via A4 highway' },
  
  // From Tissamaharama
  { from: 'TISSAMAHARAMA', to: 'MONARAGALA', distance: 81, description: 'Tissamaharama to Monaragala via A4 highway' },
  
  // From Monaragala
  { from: 'MONARAGALA', to: 'EMBILIPITIYA', distance: 55, description: 'Monaragala to Embilipitiya via local roads' },
];

async function seedRoutes() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find an admin user to assign as creator
    const admin = await Admin.findOne({ role: 'super_admin' });
    if (!admin) {
      console.log('No super_admin found. Please create an admin user first.');
      process.exit(1);
    }

    console.log(`Seeding routes with admin: ${admin.fullName}`);

    // Clear existing routes
    await Route.deleteMany({});
    console.log('Cleared existing routes');

    // Create routes
    const createdRoutes = [];
    for (const routeData of popularRoutes) {
      // Set different base prices based on route popularity and distance
      let basePricePerKm = 8.0; // Default
      
      // Adjust pricing based on distance (longer routes get better per-km rates)
      if (routeData.distance > 200) {
        basePricePerKm = 7.5; // Better rates for long-distance routes
      } else if (routeData.distance > 100) {
        basePricePerKm = 8.0; // Standard rates
      } else {
        basePricePerKm = 8.5; // Slightly higher for short routes
      }

      // Special pricing for popular routes
      if (routeData.from === 'COLOMBO' && (routeData.to === 'KANDY' || routeData.to === 'GALLE' || routeData.to === 'MATARA')) {
        basePricePerKm = 9.0; // Premium pricing for popular routes
      }

      const route = new Route({
        ...routeData,
        routeCode: `${routeData.from}-${routeData.to}`.replace(/\s+/g, ''), // Generate routeCode
        basePricePerKm,
        createdBy: admin._id,
        // Set route-specific bus type multipliers
        busTypeMultipliers: {
          Normal: 1.0,
          Express: 1.3,
          'Semi-Luxury': 1.5,
          Luxury: 2.0,
          Intercity: 1.2
        },
        // Set time-based multipliers
        pricingModifiers: {
          peakHourMultiplier: 1.2,
          weekendMultiplier: 1.1,
          holidayMultiplier: 1.3
        }
      });

      await route.save();
      createdRoutes.push(route);
      console.log(`Created route: ${route.from} -> ${route.to} (${route.distance}km, LKR ${route.basePricePerKm}/km)`);
    }

    console.log(`\nSuccessfully seeded ${createdRoutes.length} routes!`);
    
    // Display some statistics
    const totalDistance = createdRoutes.reduce((sum, route) => sum + route.distance, 0);
    const averageDistance = totalDistance / createdRoutes.length;
    
    console.log(`\nStatistics:`);
    console.log(`   Total routes: ${createdRoutes.length}`);
    console.log(`   Total distance covered: ${totalDistance} km`);
    console.log(`   Average route distance: ${averageDistance.toFixed(1)} km`);
    console.log(`   Price range: LKR ${Math.min(...createdRoutes.map(r => r.basePricePerKm))} - LKR ${Math.max(...createdRoutes.map(r => r.basePricePerKm))} per km`);

    // Show some example pricing calculations
    console.log(`\nExample Pricing (Colombo -> Kandy, 1 seat):`);
    const colomboKandy = createdRoutes.find(r => r.from === 'COLOMBO' && r.to === 'KANDY');
    if (colomboKandy) {
      const normalPrice = Math.round(colomboKandy.distance * colomboKandy.basePricePerKm * 1.0);
      const luxuryPrice = Math.round(colomboKandy.distance * colomboKandy.basePricePerKm * 2.0);
      console.log(`   Normal Bus: LKR ${normalPrice}`);
      console.log(`   Luxury Bus: LKR ${luxuryPrice}`);
    }

    process.exit(0);
  } catch (error) {
    console.error('Error seeding routes:', error);
    process.exit(1);
  }
}

// Run the seeder
seedRoutes();
