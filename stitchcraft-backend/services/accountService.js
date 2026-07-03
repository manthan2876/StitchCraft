/* services/accountService.js */
import User from '../models/User.js';
import Customer from '../models/Customer.js';
import Order from '../models/Order.js';
import Delivery from '../models/Delivery.js';
import Inventory from '../models/Inventory.js';
import Karigar from '../models/Karigar.js';
import LedgerEntry from '../models/LedgerEntry.js';
import Machine from '../models/Machine.js';
import Payment from '../models/Payment.js';
import Measurement from '../models/Measurement.js';
import Transaction from '../models/Transaction.js';
import Notification from '../models/Notification.js';
import ActionLog from '../models/ActionLog.js';

export const getRecordSummary = (modelName, doc) => {
  switch (modelName) {
    case 'Customer': return doc.name || 'Unnamed Customer';
    case 'Order': return `Order #${doc.orderId || doc._id}`;
    case 'Delivery': return `Delivery for Order #${doc.orderId}`;
    case 'Inventory': return `${doc.itemName || 'Inventory Item'} (${doc.quantity || 0})`;
    case 'Karigar': return `${doc.artisanName || 'Karigar'} - ${doc.specialization || ''}`;
    case 'LedgerEntry': return `${doc.description || 'Ledger Entry'} (₹${doc.nominal || 0})`;
    case 'Machine': return `${doc.machineNameNum || 'Machine'} (${doc.machineType || ''})`;
    case 'Payment': return `Payment (₹${doc.amount || 0})`;
    case 'Measurement': return `Measurement (${doc.apparelType || ''})`;
    case 'Transaction': return `${doc.description || 'Transaction'} (₹${doc.amount || 0})`;
    case 'Notification': return doc.message || 'Notification';
    default: return doc._id;
  }
};

export const exportAllDataService = async (user) => {
  const shopId = user.shopId;
  if (!shopId) throw new Error('No active shop selected');

  const customers = await Customer.find({ shopId });
  const orders = await Order.find({ shopId });
  const deliveries = await Delivery.find({ shopId });
  const inventory = await Inventory.find({ shopId });
  const karigars = await Karigar.find({ shopId });
  const ledgerEntries = await LedgerEntry.find({ shopId });
  const machines = await Machine.find({ shopId });
  const payments = await Payment.find({ shopId });
  const measurements = await Measurement.find({ shopId });
  const transactions = await Transaction.find({ shopId });
  const notifications = await Notification.find({ shopId });

  await ActionLog.create({
    userId: user._id,
    action: 'DOWNLOAD_DATA',
    details: `Data exported for active shop ${shopId}`,
  });

  return {
    exportedAt: new Date(),
    user: {
      name: user.name,
      email: user.email,
      role: user.role,
    },
    shopId,
    customers,
    orders,
    deliveries,
    inventory,
    karigars,
    ledgerEntries,
    machines,
    payments,
    measurements,
    transactions,
    notifications,
  };
};

export const purgeAllDataService = async (user) => {
  const shopId = user.shopId;
  if (!shopId) throw new Error('No active shop selected');

  await Customer.deleteMany({ shopId });
  await Order.deleteMany({ shopId });
  await Delivery.deleteMany({ shopId });
  await Inventory.deleteMany({ shopId });
  await Karigar.deleteMany({ shopId });
  await LedgerEntry.deleteMany({ shopId });
  await Machine.deleteMany({ shopId });
  await Payment.deleteMany({ shopId });
  await Measurement.deleteMany({ shopId });
  await Transaction.deleteMany({ shopId });
  await Notification.deleteMany({ shopId });

  await ActionLog.create({
    userId: user._id,
    action: 'DELETE_ALL_DATA',
    details: `All data cleared for active shop ${shopId}`,
  });
};

export const requestDeletionService = async (user, reason) => {
  user.status = 'deleting';
  user.deletionRequestedAt = new Date();
  user.deletionReason = reason || '';
  user.reactivated = false;
  await user.save();

  await ActionLog.create({
    userId: user._id,
    action: 'DELETE_ACCOUNT_REQUEST',
    details: reason ? `Reason: ${reason}` : 'No reason provided',
  });
};

export const checkConflictsService = async (shopId, backupData) => {
  const conflicts = [];
  const checkModelConflicts = async (Model, modelName, items) => {
    if (!Array.isArray(items) || items.length === 0) return;
    const ids = items.filter(item => item._id).map(item => item._id);
    if (ids.length === 0) return;

    const existingDocs = await Model.find({ _id: { $in: ids }, shopId });
    const existingMap = new Map(existingDocs.map(doc => [doc._id.toString(), doc]));

    for (const item of items) {
      if (!item._id) continue;
      const existing = existingMap.get(item._id.toString());
      if (existing) {
        conflicts.push({
          _id: item._id,
          model: modelName,
          name: getRecordSummary(modelName, existing),
          existing: {
            updatedAt: existing.updatedAt || existing.createdAt || new Date(),
            summary: getRecordSummary(modelName, existing)
          },
          backup: {
            updatedAt: item.updatedAt || item.createdAt || new Date(),
            summary: getRecordSummary(modelName, item)
          }
        });
      }
    }
  };

  await checkModelConflicts(Customer, 'Customer', backupData.customers);
  await checkModelConflicts(Order, 'Order', backupData.orders);
  await checkModelConflicts(Delivery, 'Delivery', backupData.deliveries);
  await checkModelConflicts(Inventory, 'Inventory', backupData.inventory);
  await checkModelConflicts(Karigar, 'Karigar', backupData.karigars);
  await checkModelConflicts(LedgerEntry, 'LedgerEntry', backupData.ledgerEntries);
  await checkModelConflicts(Machine, 'Machine', backupData.machines);
  await checkModelConflicts(Payment, 'Payment', backupData.payments);
  await checkModelConflicts(Measurement, 'Measurement', backupData.measurements);
  await checkModelConflicts(Transaction, 'Transaction', backupData.transactions);
  await checkModelConflicts(Notification, 'Notification', backupData.notifications);

  return conflicts;
};

export const importAllDataService = async (user, data, resolutions) => {
  const shopId = user.shopId;
  if (!shopId) throw new Error('No active shop selected');

  const resolutionMap = new Map(Object.entries(resolutions || {}));

  const importCollection = async (Model, items) => {
    if (!Array.isArray(items) || items.length === 0) return;
    for (const item of items) {
      item.shopId = shopId;

      if (!item._id) {
        await Model.create(item);
        continue;
      }

      const choice = resolutionMap.get(item._id.toString());
      if (choice === 'database') continue;

      const existing = await Model.findOne({ _id: item._id, shopId });
      if (existing) {
        if (choice === 'backup' || !choice) {
          await Model.replaceOne({ _id: item._id }, item);
        }
      } else {
        await Model.create(item);
      }
    }
  };

  await importCollection(Customer, data.customers);
  await importCollection(Order, data.orders);
  await importCollection(Delivery, data.deliveries);
  await importCollection(Inventory, data.inventory);
  await importCollection(Karigar, data.karigars);
  await importCollection(LedgerEntry, data.ledgerEntries);
  await importCollection(Machine, data.machines);
  await importCollection(Payment, data.payments);
  await importCollection(Measurement, data.measurements);
  await importCollection(Transaction, data.transactions);
  await importCollection(Notification, data.notifications);

  await ActionLog.create({
    userId: user._id,
    action: 'IMPORT_DATA',
    details: `Data imported/merged for active shop ${shopId}. Resolved conflicts: ${resolutionMap.size}`,
  });
};
