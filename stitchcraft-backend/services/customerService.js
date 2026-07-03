/* services/customerService.js */
import Customer from '../models/Customer.js';
import Measurement from '../models/Measurement.js';
import Order from '../models/Order.js';
import Payment from '../models/Payment.js';
import mongoose from 'mongoose';

export const findCustomerScoped = async (id, shopId) => {
  const query = mongoose.Types.ObjectId.isValid(id)
    ? { _id: id, shopId }
    : { customerId: id, shopId };
  return await Customer.findOne(query);
};

export const createCustomerService = async (reqBody, shopId) => {
  const { name, phone, email, address, measurements } = reqBody;

  const customer = await Customer.create({
    name,
    phone,
    email,
    address,
    shopId,
  });

  const measurementsRecord = await Measurement.create({
    shopId,
    customerId: customer._id,
    shirt: measurements?.shirt || {},
    pant: measurements?.pant || {},
    others: measurements?.others || '',
  });

  const result = customer.toJSON();
  result.measurements = measurementsRecord;
  return result;
};

export const getCustomerProfileService = async (customerId, shopId) => {
  const customer = await findCustomerScoped(customerId, shopId);
  if (!customer) return null;

  let measurements = await Measurement.findOne({ customerId: customer._id });
  if (!measurements) {
    measurements = await Measurement.create({
      shopId,
      customerId: customer._id,
    });
  }

  const orders = await Order.find({ customer: customer._id, shopId }).sort({ createdAt: -1 });

  const orderIds = orders.map(o => o._id);
  const payments = await Payment.find({ orderId: { $in: orderIds }, shopId }).populate('orderId');

  const result = customer.toJSON();
  result.measurements = measurements;
  result.orders = orders;
  result.payments = payments;

  return result;
};

export const updateCustomerService = async (customerId, reqBody, shopId) => {
  const customer = await findCustomerScoped(customerId, shopId);
  if (!customer) return null;

  const { name, phone, email, address, measurements } = reqBody;

  if (name) customer.name = name;
  if (phone) customer.phone = phone;
  if (email !== undefined) customer.email = email;
  if (address !== undefined) customer.address = address;

  const updatedCustomer = await customer.save();

  let measurementsRecord = await Measurement.findOne({ customerId: customer._id });
  if (!measurementsRecord) {
    measurementsRecord = new Measurement({
      shopId,
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
  return result;
};

export const deleteCustomerService = async (customerId, shopId) => {
  const customer = await findCustomerScoped(customerId, shopId);
  if (!customer) return false;

  await Customer.deleteOne({ _id: customer._id });
  await Measurement.deleteOne({ customerId: customer._id });

  await Order.updateMany(
    { customer: customer._id, shopId },
    { $unset: { customer: "" }, customerName: `${customer.name} (Deleted)` }
  );

  return true;
};
