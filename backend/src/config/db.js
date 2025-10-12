const mongoose = require("mongoose");

async function connectDB() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error("MONGODB_URI missing in .env");
  try {
    await mongoose.connect(uri, {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 10000,
    });
    console.log("MongoDB connected:", mongoose.connection.host);
  } catch (err) {
    console.error("MongoDB connection error:", err.message);
    process.exit(1);
  }
}
module.exports = { connectDB };
