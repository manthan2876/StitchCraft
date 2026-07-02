/* controllers/accountController.js */
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

const getRecordSummary = (modelName, doc) => {
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

// @desc    Download all data as JSON
// @route   POST /api/auth/account/download-data
// @access  Private
export const downloadAllData = async (req, res) => {
  try {
    const { password } = req.body;
    if (!password) {
      return res.status(400).json({ message: 'Password is required' });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Incorrect password' });
    }

    const shopId = user.shopId;
    if (!shopId) {
      return res.status(400).json({ message: 'No active shop selected' });
    }

    // Gather all data
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

    // Log action
    await ActionLog.create({
      userId: user._id,
      action: 'DOWNLOAD_DATA',
      details: `Data exported for active shop ${shopId}`,
    });

    res.json({
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
    });
  } catch (error) {
    console.error('Download data error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete all active shop data
// @route   POST /api/auth/account/delete-all-data
// @access  Private
export const deleteAllData = async (req, res) => {
  try {
    const { password } = req.body;
    if (!password) {
      return res.status(400).json({ message: 'Password is required' });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Incorrect password' });
    }

    const shopId = user.shopId;
    if (!shopId) {
      return res.status(400).json({ message: 'No active shop selected' });
    }

    // Delete all records of the active shop
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

    // Log action
    await ActionLog.create({
      userId: user._id,
      action: 'DELETE_ALL_DATA',
      details: `All data cleared for active shop ${shopId}`,
    });

    res.json({ message: 'All shop data deleted successfully' });
  } catch (error) {
    console.error('Delete all data error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Request account deletion
// @route   POST /api/auth/account/delete-account
// @access  Private
export const deleteAccountRequest = async (req, res) => {
  try {
    const { password, reason } = req.body;
    if (!password) {
      return res.status(400).json({ message: 'Password is required' });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Incorrect password' });
    }

    // Mark account for deletion (grace period 15 days)
    user.status = 'deleting';
    user.deletionRequestedAt = new Date();
    user.deletionReason = reason || '';
    user.reactivated = false;
    await user.save();

    // Log action
    await ActionLog.create({
      userId: user._id,
      action: 'DELETE_ACCOUNT_REQUEST',
      details: reason ? `Reason: ${reason}` : 'No reason provided',
    });

    res.json({ message: 'Account scheduled for deletion. Logging out...' });
  } catch (error) {
    console.error('Delete account request error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Check conflicts in uploaded JSON import data
// @route   POST /api/auth/account/check-conflicts
// @access  Private
export const checkImportConflicts = async (req, res) => {
  try {
    const { data } = req.body;
    if (!data) {
      return res.status(400).json({ message: 'Backup data is required' });
    }

    const shopId = req.user.shopId;
    if (!shopId) {
      return res.status(400).json({ message: 'No active shop selected' });
    }

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

    await checkModelConflicts(Customer, 'Customer', data.customers);
    await checkModelConflicts(Order, 'Order', data.orders);
    await checkModelConflicts(Delivery, 'Delivery', data.deliveries);
    await checkModelConflicts(Inventory, 'Inventory', data.inventory);
    await checkModelConflicts(Karigar, 'Karigar', data.karigars);
    await checkModelConflicts(LedgerEntry, 'LedgerEntry', data.ledgerEntries);
    await checkModelConflicts(Machine, 'Machine', data.machines);
    await checkModelConflicts(Payment, 'Payment', data.payments);
    await checkModelConflicts(Measurement, 'Measurement', data.measurements);
    await checkModelConflicts(Transaction, 'Transaction', data.transactions);
    await checkModelConflicts(Notification, 'Notification', data.notifications);

    res.json({
      hasConflicts: conflicts.length > 0,
      conflicts
    });
  } catch (error) {
    console.error('Check conflicts error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Import shop data from JSON with conflict resolution choices
// @route   POST /api/auth/account/import-data
// @access  Private
export const importAllData = async (req, res) => {
  try {
    const { password, data, resolutions } = req.body;
    if (!password) {
      return res.status(400).json({ message: 'Password is required' });
    }
    if (!data) {
      return res.status(400).json({ message: 'Import data is required' });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Incorrect password' });
    }

    const shopId = user.shopId;
    if (!shopId) {
      return res.status(400).json({ message: 'No active shop selected' });
    }

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
        if (choice === 'database') {
          continue;
        }

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

    // Log Action
    await ActionLog.create({
      userId: user._id,
      action: 'IMPORT_DATA',
      details: `Data imported/merged for active shop ${shopId}. Resolved conflicts: ${resolutionMap.size}`,
    });

    res.json({ message: 'All shop data imported successfully.' });
  } catch (error) {
    console.error('Import data error:', error);
    res.status(500).json({ message: error.message });
  }
};
