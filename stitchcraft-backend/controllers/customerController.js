/* controllers/customerController.js */
import Customer from '../models/Customer.js';
import {
  createCustomerService,
  getCustomerProfileService,
  updateCustomerService,
  deleteCustomerService,
} from '../services/customerService.js';

// @desc    Create a new customer
// @route   POST /api/customers
// @access  Private
export const createCustomer = async (req, res) => {
  try {
    const { name, phone } = req.body;
    if (!name || !phone) {
      return res.status(400).json({ message: 'Please provide customer name and phone number' });
    }

    const result = await createCustomerService(req.body, req.user.shopId);
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
    const filter = { shopId: req.user.shopId };

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
    const result = await getCustomerProfileService(req.params.id, req.user.shopId);
    if (!result) return res.status(404).json({ message: 'Customer not found' });
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
    const result = await updateCustomerService(req.params.id, req.body, req.user.shopId);
    if (!result) return res.status(404).json({ message: 'Customer not found' });
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
    const success = await deleteCustomerService(req.params.id, req.user.shopId);
    if (!success) return res.status(404).json({ message: 'Customer not found' });
    res.json({ message: 'Customer profile and measurements deleted successfully' });
  } catch (error) {
    console.error('Delete customer error:', error);
    res.status(500).json({ message: error.message });
  }
};
