/* services/customerService.js */
import Customer from '../models/Customer.js';
import Measurement from '../models/Measurement.js';
import Order from '../models/Order.js';
import Payment from '../models/Payment.js';
import { isValidIdentifier } from '../utils/identifiers.js';

export const findCustomerScoped = async (id, shopId) => {
  if (!id) return null;
  let customer = await Customer.findOne({ _id: id, shopId });
  if (!customer) {
    customer = await Customer.findOne({ id: id, shopId });
  }
  if (!customer) {
    customer = await Customer.findOne({ customerId: id, shopId });
  }
  if (!customer && typeof id === 'string') {
    const clean = id.replace(/\D/g, '');
    if (clean.length >= 10) {
      const last10 = clean.slice(-10);
      customer = await Customer.findOne({ shopId, phone: { $regex: `${last10}$` } });
    }
  }
  return customer;
};

export const createCustomerService = async (reqBody, shopId) => {
  const { name, phone, email, address, measurements, idempotencyKey: rawIdempotencyKey } = reqBody;
  const idempotencyKey = rawIdempotencyKey || reqBody.clientMutationId;

  if (idempotencyKey) {
    const existingByIdempotency = await Customer.findOne({ shopId, idempotencyKey });
    if (existingByIdempotency) {
      const measurementsRecord = await Measurement.findOne({ customerId: existingByIdempotency._id });
      const result = typeof existingByIdempotency.toJSON === 'function' ? existingByIdempotency.toJSON() : { ...existingByIdempotency };
      result.measurements = measurementsRecord;
      return result;
    }
  }

  const cleanPhone = (phone || '').replace(/[\s\-\(\)\.]/g, '');

  let customer = null;
  if (cleanPhone) {
    customer = await Customer.findOne({ shopId, phone: cleanPhone });
    if (!customer && cleanPhone.length >= 10) {
      const last10 = cleanPhone.slice(-10);
      customer = await Customer.findOne({ shopId, phone: { $regex: `${last10}$` } });
    }
  }

  if (customer) {
    if (name) customer.name = name;
    if (email) customer.email = email;
    if (address) customer.address = address;
    if (idempotencyKey && !customer.idempotencyKey) customer.idempotencyKey = idempotencyKey;
    await customer.save();
  } else {
    customer = await Customer.create({
      name,
      phone: cleanPhone || phone,
      email,
      address,
      shopId,
      idempotencyKey: idempotencyKey || null,
    });
  }

  let measurementsRecord = await Measurement.findOne({ customerId: customer._id });
  if (!measurementsRecord) {
    measurementsRecord = await Measurement.create({
      shopId,
      customerId: customer._id,
      shirt: measurements?.shirt || {},
      pant: measurements?.pant || {},
      others: measurements?.others || '',
    });
  } else if (measurements) {
    if (measurements.shirt) {
      measurementsRecord.shirt = { ...(measurementsRecord.shirt || {}), ...measurements.shirt };
    }
    if (measurements.pant) {
      measurementsRecord.pant = { ...(measurementsRecord.pant || {}), ...measurements.pant };
    }
    if (measurements.others !== undefined) {
      measurementsRecord.others = measurements.others;
    }
    await measurementsRecord.save();
  }

  const result = customer.toJSON();
  result.measurements = measurementsRecord;
  return result;
};

export const getCustomerProfileService = async (customerId, shopId) => {
  const customer = await findCustomerScoped(customerId, shopId);
  if (!customer) return null;

  const custId = customer._id || customer.id;
  const cleanPhone = (customer.phone || '').replace(/\D/g, '').slice(-10);

  let measurements = await Measurement.findOne({ customerId: custId });
  if (!measurements && typeof custId !== 'string') {
    measurements = await Measurement.findOne({ customerId: String(custId) });
  }
  if (!measurements) {
    measurements = await Measurement.create({
      shopId,
      customerId: custId,
    });
  }

  // Broad order matching by ID, string ID, clean customerPhone, or customerName
  const orderConditions = [
    { customer: custId },
    { customerId: custId },
    { customer: String(custId) },
    { customerId: String(custId) },
  ];
  if (cleanPhone) {
    orderConditions.push({ customerPhone: customer.phone });
    orderConditions.push({ customerPhone: cleanPhone });
    orderConditions.push({ customerPhone: `+91${cleanPhone}` });
    orderConditions.push({ customerPhone: `91${cleanPhone}` });
  }
  if (customer.name) {
    orderConditions.push({ customerName: customer.name });
  }

  const orders = await Order.find({
    shopId,
    $or: orderConditions,
  }).sort({ createdAt: -1 });

  const orderIds = orders.map(o => o._id || o.id);
  const payments = await Payment.find({ orderId: { $in: orderIds }, shopId }).populate('orderId');

  const result = typeof customer.toJSON === 'function' ? customer.toJSON() : { ...customer };
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
        ...(measurementsRecord.shirt?.toObject?.() || measurementsRecord.shirt || {}),
        ...measurements.shirt,
      };
    }
    if (measurements.pant) {
      measurementsRecord.pant = {
        ...(measurementsRecord.pant?.toObject?.() || measurementsRecord.pant || {}),
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
