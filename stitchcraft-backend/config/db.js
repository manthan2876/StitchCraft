import mongoose from 'mongoose';

// Import models to register schemas for Step 1
import './../models/User.js';
import './../models/Shop.js';
import './../models/Customer.js';
import './../models/Order.js';
import './../models/Payment.js';
import './../models/Delivery.js';
import './../models/Notification.js';
import './../models/Counter.js';

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`Error connecting to MongoDB: ${error.message}`);
    process.exit(1);
  }
};

export default connectDB;
