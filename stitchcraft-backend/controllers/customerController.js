import Customer from '../models/Customer.js';
import Measurement from '../models/Measurement.js';
import Order from '../models/Order.js';
import Payment from '../models/Payment.js';
import mongoose from 'mongoose';

// Helper to find a customer by ID or custom customerId, scoped to the current shop
const findCustomerScoped = async (id, shopId) => {
  const query = mongoose.Types.ObjectId.isValid(id)
    ? { _id: id, shopId }
    : { customerId: id, shopId };
  return await Customer.findOne(query);
};

// @desc    Create a new customer
// @route   POST /api/customers
// @access  Private
export const createCustomer = async (req, res) => {
  try {
    const { name, phone, email, address, measurements } = req.body;

    if (!name || !phone) {
      return res.status(400).json({ message: 'Please provide customer name and phone number' });
    }

    // Create customer
    const customer = await Customer.create({
      name,
      phone,
      email,
      address,
      shopId: req.user.shopId,
    });

    // Create associated measurements record
    const measurementsRecord = await Measurement.create({
      shopId: req.user.shopId,
      customerId: customer._id,
      shirt: measurements?.shirt || {},
      pant: measurements?.pant || {},
      others: measurements?.others || '',
    });

    // Return customer with measurements attached
    const result = customer.toJSON();
    result.measurements = measurementsRecord;

    res.status(201).json(result);
  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all customers linked to the shop (with optional search)
// @route   GET /api/customers
// @access  Private
export const getCustomers = async (req, res) => {
  try {
    const search = req.query.search || '';
    
    // Scoped to shopId
    const filter = {
      shopId: req.user.shopId,
    };

    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { customerId: { $regex: search, $options: 'i' } },
      ];
    }

    const customers = await Customer.find(filter).sort({ createdAt: -1 });
    res.json(customers);
  } catch (error) {
    console.error('Get customers error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get a single customer's full profile, measurements, and histories
// @route   GET /api/customers/:id
// @access  Private
export const getCustomerById = async (req, res) => {
  try {
    const customer = await findCustomerScoped(req.params.id, req.user.shopId);

    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    // Find measurements
    let measurements = await Measurement.findOne({ customerId: customer._id });
    if (!measurements) {
      // Create one if it does not exist
      measurements = await Measurement.create({
        shopId: req.user.shopId,
        customerId: customer._id,
      });
    }

    // Find orders
    const orders = await Order.find({ customer: customer._id, shopId: req.user.shopId }).sort({ createdAt: -1 });

    // Find payments for these orders
    const orderIds = orders.map(o => o._id);
    const payments = await Payment.find({ orderId: { $in: orderIds }, shopId: req.user.shopId }).populate('orderId');

    const result = customer.toJSON();
    result.measurements = measurements;
    result.orders = orders;
    result.payments = payments;

    res.json(result);
  } catch (error) {
    console.error('Get customer by ID error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update customer contact info or measurements
// @route   PUT /api/customers/:id
// @access  Private
export const updateCustomer = async (req, res) => {
  try {
    const customer = await findCustomerScoped(req.params.id, req.user.shopId);

    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    const { name, phone, email, address, measurements } = req.body;

    if (name) customer.name = name;
    if (phone) customer.phone = phone;
    if (email !== undefined) customer.email = email;
    if (address !== undefined) customer.address = address;

    const updatedCustomer = await customer.save();

    // Find or create measurements to update
    let measurementsRecord = await Measurement.findOne({ customerId: customer._id });
    if (!measurementsRecord) {
      measurementsRecord = new Measurement({
        shopId: req.user.shopId,
        customerId: customer._id,
      });
    }

    if (measurements) {
      if (measurements.shirt) {
        measurementsRecord.shirt = {
          ...measurementsRecord.shirt.toObject(),
          ...measurements.shirt,
        };
      }
      if (measurements.pant) {
        measurementsRecord.pant = {
          ...measurementsRecord.pant.toObject(),
          ...measurements.pant,
        };
      }
      if (measurements.others !== undefined) {
        measurementsRecord.others = measurements.others;
      }
      await measurementsRecord.save();
    }

    const result = updatedCustomer.toJSON();
    result.measurements = measurementsRecord;

    res.json(result);
  } catch (error) {
    console.error('Update customer error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Permanently delete a customer profile and associated measurements
// @route   DELETE /api/customers/:id
// @access  Private
export const deleteCustomer = async (req, res) => {
  try {
    const customer = await findCustomerScoped(req.params.id, req.user.shopId);

    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    // Delete customer profile
    await Customer.deleteOne({ _id: customer._id });

    // Delete customer measurements
    await Measurement.deleteOne({ customerId: customer._id });

    // Mark associated orders as having a deleted customer (optional, keep order history)
    await Order.updateMany(
      { customer: customer._id, shopId: req.user.shopId },
      { $unset: { customer: "" }, customerName: `${customer.name} (Deleted)` }
    );

    res.json({ message: 'Customer profile and measurements deleted successfully' });
  } catch (error) {
    console.error('Delete customer error:', error);
    res.status(500).json({ message: error.message });
  }
};
