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

// Core Business Logic: Create Order
export const createOrderService = async (reqBody, shopId, userId) => {
  const {
    customerName,
    apparelType,
    deliveryDate,
    price,
    advancePaid,
    fabric,
    paymentType,
    measurements,
    needsAster,
    asterQuantity,
    asterInventoryItem,
    asterSellingPrice,
    assignedKarigar,
    assignedMachine,
    measurementType,
    maapImageUrl,
    fabricImageUrl,
  } = reqBody;

  const customerObj = await resolveCustomer(reqBody, shopId);

  if (measurementType !== 'Maap' && measurements) {
    await updateCustomerMeasurements(customerObj._id, measurements, shopId);
  }

  let measurementsSnapshot = null;
  if (measurements) {
    measurementsSnapshot = {
      shirt: measurements.shirt || null,
      pant: measurements.pant || null,
      others: measurements.others || '',
    };
  } else {
    const template = await Measurement.findOne({ customerId: customerObj._id });
    if (template) {
      measurementsSnapshot = {
        shirt: template.shirt ? (typeof template.shirt.toObject === 'function' ? template.shirt.toObject() : template.shirt) : null,
        pant: template.pant ? (typeof template.pant.toObject === 'function' ? template.pant.toObject() : template.pant) : null,
        others: template.others || '',
      };
    }
  }

  const order = await Order.create({
    customerName: customerObj.name,
    customer: customerObj._id,
    apparelType,
    deliveryDate,
    price,
    fabric: fabric || '',
    shopId,
    status: 'Incoming',
    needsAster: needsAster || false,
    asterQuantity: needsAster ? (Number(asterQuantity) || 0) : 0,
    asterInventoryItem: (needsAster && asterInventoryItem) ? asterInventoryItem : null,
    asterSellingPrice: needsAster ? (Number(asterSellingPrice) || 0) : 0,
    measurementType: measurementType || 'Maap',
    maapImageUrl: maapImageUrl || '',
    fabricImageUrl: fabricImageUrl || '',
    assignedKarigar: assignedKarigar || null,
    assignedMachine: assignedMachine || null,
    measurementsSnapshot,
  });

  const payment = await Payment.create({
    shopId,
    orderId: order._id,
    totalAmount: price + (needsAster ? (Number(asterQuantity) * Number(asterSellingPrice)) : 0),
    paidAmount: advancePaid || 0,
    paymentType: paymentType || 'Cash',
  });

  if (advancePaid && Number(advancePaid) > 0) {
    await Transaction.create({
      shopId,
      orderId: order._id,
      amount: Number(advancePaid),
      paymentType: paymentType || 'Cash',
      type: 'Payment',
    });
    await syncPaymentFromTransactions(order._id, shopId);
  }

  const delivery = await Delivery.create({
    shopId,
    orderId: order._id,
    deliveryDate,
    status: 'Pending',
  });

  await Notification.create({
    shopId,
    customerId: customerObj._id,
    orderId: order._id,
    message: `New order ${order.orderId} created for ${customerObj.name}. Delivery due on ${new Date(deliveryDate).toLocaleDateString()}.`,
  });

  const result = order.toJSON();
  result.payment = payment;
  result.delivery = delivery;
  return result;
};

// Core Business Logic: Update Order
export const updateOrderService = async (orderId, reqBody, shopId, userName) => {
  const order = await findOrderScoped(orderId, shopId);
  if (!order) return null;

  const {
    status,
    deliveryDate,
    price,
    fabric,
    needsAster,
    asterQuantity,
    asterInventoryItem,
    asterSellingPrice,
    assignedKarigar,
    assignedMachine,
    measurementType,
    maapImageUrl,
    fabricImageUrl,
  } = reqBody;

  if (deliveryDate) {
    order.deliveryDate = deliveryDate;
    await Delivery.updateOne({ orderId: order._id }, { deliveryDate });
  }
  if (price !== undefined) order.price = price;
  if (fabric !== undefined) order.fabric = fabric;
  if (needsAster !== undefined) order.needsAster = needsAster;
  if (asterQuantity !== undefined) order.asterQuantity = Number(asterQuantity) || 0;
  if (asterInventoryItem !== undefined) order.asterInventoryItem = asterInventoryItem || null;
  if (asterSellingPrice !== undefined) order.asterSellingPrice = Number(asterSellingPrice) || 0;
  if (measurementType !== undefined) order.measurementType = measurementType;
  if (maapImageUrl !== undefined) order.maapImageUrl = maapImageUrl;
  if (fabricImageUrl !== undefined) order.fabricImageUrl = fabricImageUrl;
  if (assignedKarigar !== undefined) order.assignedKarigar = assignedKarigar || null;
  if (assignedMachine !== undefined) order.assignedMachine = assignedMachine || null;

  let statusChanged = false;
  let oldStatus = order.status;
  const newStatus = status;

  if (newStatus && newStatus !== order.status) {
    await handleAstarStockAdjustment(order, newStatus, shopId);
    order.status = newStatus;
    statusChanged = true;
  }

  const updatedOrder = await order.save();
  await syncPaymentFromTransactions(order._id, shopId);

  if (statusChanged) {
    if (status === 'Delivered') {
      await Delivery.updateOne(
        { orderId: order._id },
        { status: 'Delivered', deliveredBy: userName || 'Owner' }
      );
      await Notification.create({
        shopId,
        customerId: order.customer,
        orderId: order._id,
        message: `Order ${order.orderId} has been successfully delivered.`,
      });
    } else {
      await Notification.create({
        shopId,
        customerId: order.customer,
        orderId: order._id,
        message: `Order ${order.orderId} status changed from ${oldStatus} to ${status}.`,
      });
    }
  }

  const payment = await Payment.findOne({ orderId: order._id });
  const delivery = await Delivery.findOne({ orderId: order._id });

  const result = updatedOrder.toJSON();
  result.payment = payment;
  result.delivery = delivery;
  return result;
};

// Core Business Logic: Delete Order
export const deleteOrderService = async (orderId, shopId) => {
  const order = await findOrderScoped(orderId, shopId);
  if (!order) return null;

  if (order.customer) {
    await Customer.updateOne(
      { _id: order.customer, shopId },
      { $inc: { ordersCount: -1 } }
    );
  }

  await Payment.deleteOne({ orderId: order._id, shopId });
  await Delivery.deleteOne({ orderId: order._id, shopId });
  await Notification.deleteMany({ orderId: order._id, shopId });
  await Transaction.deleteMany({ orderId: order._id, shopId });
  await Order.deleteOne({ _id: order._id, shopId });
  return true;
};
