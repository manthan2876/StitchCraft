import Customer from '../models/Customer.js';
import Order from '../models/Order.js';
import Inventory from '../models/Inventory.js';
import LedgerEntry from '../models/LedgerEntry.js';
import SyncMutation from '../models/SyncMutation.js';
import { updateOrderService, createOrderService } from '../services/orderService.js';
import { updateCustomerService, createCustomerService, deleteCustomerService } from '../services/customerService.js';

export const pushMutations = async (req, res) => {
  try {
    const shopId = req.user.shopId;
    const { mutations } = req.body;

    if (!Array.isArray(mutations)) {
      return res.status(400).json({ message: 'Payload must contain a mutations array' });
    }

    const results = [];

    for (const m of mutations) {
      const mutationId = m.clientMutationId || m.client_mutation_id || m.id;
      const entityType = m.entityType || m.entity_type || m.table_name;
      const entityId = m.entityId || m.entity_id || m.record_id;
      const operation = m.operation || m.action;
      const baseVersion = m.baseVersion ?? m.base_version;
      const payload = m.payload || {};

      if (!mutationId) {
        results.push({
          clientMutationId: null,
          status: 'failed',
          error: 'Missing clientMutationId',
        });
        continue;
      }

      // Check if already processed (server idempotency)
      const existing = await SyncMutation.findOne({ shopId, mutationId });
      if (existing) {
        results.push({
          clientMutationId: mutationId,
          status: 'synced',
          isReplay: true,
          data: existing.response,
        });
        continue;
      }

      try {
        let resultData = null;

        if (entityType === 'customers') {
          if (operation === 'create') {
            resultData = await createCustomerService({ ...payload, shopId });
          } else if (operation === 'update') {
            resultData = await updateCustomerService(entityId, { ...payload, base_version: baseVersion }, shopId);
          } else if (operation === 'delete') {
            resultData = await deleteCustomerService(entityId, shopId);
          }
        } else if (entityType === 'orders') {
          if (operation === 'create') {
            resultData = await createOrderService({ ...payload, shopId }, shopId);
          } else if (operation === 'update') {
            resultData = await updateOrderService(entityId, { ...payload, base_version: baseVersion }, shopId, req.user.name);
          }
        } else if (entityType === 'inventory') {
          if (operation === 'create') {
            resultData = await Inventory.create({ ...payload, shopId, version: 1 });
          } else if (operation === 'update') {
            const item = await Inventory.findOne({ _id: entityId, shopId });
            if (!item) {
              throw Object.assign(new Error('Inventory item not found'), { statusCode: 404 });
            }
            if (baseVersion !== undefined && baseVersion !== null && Number(item.version || 1) !== Number(baseVersion)) {
              throw Object.assign(new Error('Conflict: concurrent modification detected'), {
                statusCode: 409,
                serverVersion: item.version || 1,
                currentData: item.toJSON ? item.toJSON() : item,
              });
            }
            Object.assign(item, payload);
            item.version = Number(item.version || 1) + 1;
            resultData = await item.save();
          } else if (operation === 'delete') {
            await Inventory.deleteOne({ _id: entityId, shopId });
            resultData = { deleted: true };
          }
        } else if (entityType === 'expenses') {
          if (operation === 'create') {
            resultData = await LedgerEntry.create({ ...payload, shopId, version: 1 });
          } else if (operation === 'update') {
            const entry = await LedgerEntry.findOne({ _id: entityId, shopId });
            if (!entry) {
              throw Object.assign(new Error('Expense entry not found'), { statusCode: 404 });
            }
            if (baseVersion !== undefined && baseVersion !== null && Number(entry.version || 1) !== Number(baseVersion)) {
              throw Object.assign(new Error('Conflict: concurrent modification detected'), {
                statusCode: 409,
                serverVersion: entry.version || 1,
                currentData: entry.toJSON ? entry.toJSON() : entry,
              });
            }
            Object.assign(entry, payload);
            entry.version = Number(entry.version || 1) + 1;
            resultData = await entry.save();
          } else if (operation === 'delete') {
            await LedgerEntry.deleteOne({ _id: entityId, shopId });
            resultData = { deleted: true };
          }
        }

        // Commit mutation record
        await SyncMutation.create({
          shopId,
          mutationId,
          entityType,
          entityId,
          operation,
          statusCode: 200,
          response: resultData,
          createdAt: new Date().toISOString(),
        });

        results.push({
          clientMutationId: mutationId,
          status: 'synced',
          serverVersion: resultData?.version,
          data: resultData,
        });
      } catch (err) {
        if (err.statusCode === 409) {
          results.push({
            clientMutationId: mutationId,
            status: 'conflict',
            serverVersion: err.serverVersion,
            currentData: err.currentData,
            error: err.message,
          });
        } else {
          results.push({
            clientMutationId: mutationId,
            status: 'failed',
            error: err.message,
          });
        }
      }
    }

    res.json({ results });
  } catch (error) {
    console.error('Batch sync push error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const pullChanges = async (req, res) => {
  try {
    const shopId = req.user.shopId;
    const since = req.query.since;

    const [customers, orders, inventory, expenses] = await Promise.all([
      Customer.find({ shopId, isDeleted: { $ne: true } }),
      Order.find({ shopId }),
      Inventory.find({ shopId }),
      LedgerEntry.find({ shopId }),
    ]);

    res.json({
      customers: customers.map((c) => ({ ...c.toJSON(), version: c.version || 1 })),
      orders: orders.map((o) => ({ ...o.toJSON(), version: o.version || 1 })),
      inventory: inventory.map((i) => ({ ...i.toJSON(), version: i.version || 1 })),
      expenses: expenses.map((e) => ({ ...e.toJSON(), version: e.version || 1 })),
      serverTime: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Batch sync pull error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getSyncStatus = async (req, res) => {
  res.json({
    status: 'healthy',
    shopId: req.user.shopId,
    serverTime: new Date().toISOString(),
  });
};

