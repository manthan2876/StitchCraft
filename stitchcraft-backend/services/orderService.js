/* services/orderService.js */
import mongoose from 'mongoose';
import Order from '../models/Order.js';
import Customer from '../models/Customer.js';
import Payment from '../models/Payment.js';
import Delivery from '../models/Delivery.js';
import Notification from '../models/Notification.js';
import Measurement from '../models/Measurement.js';
import Inventory from '../models/Inventory.js';
import Transaction from '../models/Transaction.js';

export const ASTAR_DEDUCT_STATUSES = ['Stitching', 'Checking', 'Ready', 'Delivered'];

export const findOrderScoped = async (id, shopId) => {
  const query = mongoose.Types.ObjectId.isValid(id)
    ? { _id: id, shopId }
    : { orderId: id, shopId };
  return await Order.findOne(query)
    .populate('assignedKarigar')
    .populate('assignedMachine')
    .populate('asterInventoryItem');
};

export const syncPaymentFromTransactions = async (orderId, shopId) => {
  const order = await Order.findById(orderId);
  if (!order) return null;

  const asterPrice = order.needsAster ? (order.asterSellingPrice * order.asterQuantity) : 0;
  const totalOrderValue = order.price + asterPrice;

  const transactions = await Transaction.find({ orderId, shopId });
  const totalPaid = transactions.reduce((sum, tx) => {
    if (tx.type === 'Payment') return sum + tx.amount;
    if (tx.type === 'Refund') return sum - tx.amount;
    return sum;
  }, 0);

  let payment = await Payment.findOne({ orderId, shopId });
  if (!payment) {
    payment = new Payment({ orderId, shopId, totalAmount: totalOrderValue });
  } else {
    payment.totalAmount = totalOrderValue;
  }

  payment.paidAmount = totalPaid;
  payment.balanceAmount = Math.max(0, payment.totalAmount - totalPaid);
  payment.status = payment.balanceAmount === 0 ? 'Paid' : (totalPaid > 0 ? 'Partial' : 'Pending');

  await payment.save();
  return payment;
};

export const resolveCustomer = async (reqBody, shopId) => {
  const { customerId, customerName, customerPhone, customerAddress } = reqBody;
  let customerObj = null;

  if (customerId) {
    const custQuery = mongoose.Types.ObjectId.isValid(customerId)
      ? { _id: customerId, shopId }
      : { customerId, shopId };
    customerObj = await Customer.findOne(custQuery);
  }

  if (!customerObj) {
    const nameQuery = customerPhone
      ? { name: customerName, phone: customerPhone, shopId }
      : { name: customerName, shopId };
    customerObj = await Customer.findOne(nameQuery);
  }

  if (!customerObj) {
    customerObj = await Customer.create({
      name: customerName,
      phone: customerPhone || '0000000000',
      email: '',
      address: customerAddress || '',
      shopId,
      ordersCount: 1,
    });
  } else {
    customerObj.ordersCount = (customerObj.ordersCount || 0) + 1;
    await customerObj.save();
  }

  return customerObj;
};

export const updateCustomerMeasurements = async (customerId, measurements, shopId) => {
  let measurementRecord = await Measurement.findOne({ customerId });
  if (!measurementRecord) {
    measurementRecord = new Measurement({
      shopId,
      customerId,
    });
  }

  if (measurements.shirt) {
    measurementRecord.shirt = {
      ...measurementRecord.shirt.toObject(),
      ...measurements.shirt,
    };
  }
  if (measurements.pant) {
    measurementRecord.pant = {
      ...measurementRecord.pant.toObject(),
      ...measurements.pant,
    };
  }
  if (measurements.others !== undefined) {
    measurementRecord.others = measurements.others;
  }
  await measurementRecord.save();
  return measurementRecord;
};

export const handleAstarStockAdjustment = async (order, newStatus, shopId) => {
  const willDeduct = ASTAR_DEDUCT_STATUSES.includes(newStatus);
  const wasDeducted = order.asterDeducted;

  if (order.needsAster && order.asterQuantity > 0 && order.asterInventoryItem) {
    if (willDeduct && !wasDeducted) {
      const invItem = await Inventory.findOne({ _id: order.asterInventoryItem, shopId });
      if (invItem) {
        invItem.quantity = Math.max(0, invItem.quantity - order.asterQuantity);
        await invItem.save();
        order.asterDeducted = true;
        await Notification.create({
          shopId,
          orderId: order._id,
          message: `Astar stock reduced by ${order.asterQuantity} ${invItem.unit} for order ${order.orderId} (${invItem.itemName}).`,
        });
      }
    } else if (!willDeduct && wasDeducted) {
      const invItem = await Inventory.findOne({ _id: order.asterInventoryItem, shopId });
      if (invItem) {
        invItem.quantity = invItem.quantity + order.asterQuantity;
        await invItem.save();
        order.asterDeducted = false;
      }
    }
  }
};
