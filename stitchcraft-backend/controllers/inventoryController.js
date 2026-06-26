import Inventory from '../models/Inventory.js';
import LedgerEntry from '../models/LedgerEntry.js';
import mongoose from 'mongoose';

// @desc    Create a new inventory item
// @route   POST /api/inventory
// @access  Private
export const createInventoryItem = async (req, res) => {
  try {
    const { itemName, itemType, quantity, unit, minQuantity, purchaseAmount, description, costPerUnit } = req.body;

    if (!itemName) {
      return res.status(400).json({ message: 'Item name is required' });
    }

    if (!itemType) {
      return res.status(400).json({ message: 'Item type is required' });
    }

    const pAmount = purchaseAmount !== undefined ? Number(purchaseAmount) : 0;

    const itemData = {
      shopId: req.user.shopId,
      itemName,
      itemType,
      quantity: quantity !== undefined ? Number(quantity) : 0,
      unit: unit || 'meters',
      minQuantity: minQuantity !== undefined ? Number(minQuantity) : 10,
      costPerUnit: costPerUnit !== undefined ? Number(costPerUnit) : 0,
    };

    if (pAmount > 0) {
      itemData.lastPurchaseAmount = pAmount;
      itemData.purchaseHistory = [{ amount: pAmount, date: new Date() }];
    }

    const item = await Inventory.create(itemData);

    if (pAmount > 0) {
      await LedgerEntry.create({
        shopId: req.user.shopId,
        amount: pAmount,
        category: 'Inventory',
        description: description || `Purchased ${quantity || 0} ${unit || 'meters'} of ${itemName}`,
        referenceId: item._id,
      });
    }

    res.status(201).json(item);
  } catch (error) {
    console.error('Create inventory item error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all inventory items for a shop
// @route   GET /api/inventory
// @access  Private
export const getInventory = async (req, res) => {
  try {
    const { search, itemType, status } = req.query;
    const filter = { shopId: req.user.shopId };

    if (search) {
      filter.itemName = { $regex: search, $options: 'i' };
    }
    if (itemType) {
      filter.itemType = itemType;
    }
    if (status) {
      filter.status = status;
    }

    const inventory = await Inventory.find(filter).sort({ itemName: 1 });
    res.json(inventory);
  } catch (error) {
    console.error('Get inventory error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get details of a single inventory item
// @route   GET /api/inventory/:id
// @access  Private
export const getInventoryItemById = async (req, res) => {
  try {
    const item = await Inventory.findOne({ _id: req.params.id, shopId: req.user.shopId });

    if (!item) {
      return res.status(404).json({ message: 'Inventory item not found' });
    }

    res.json(item);
  } catch (error) {
    console.error('Get inventory item by ID error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update an inventory item
// @route   PUT /api/inventory/:id
// @access  Private
export const updateInventoryItem = async (req, res) => {
  try {
    const item = await Inventory.findOne({ _id: req.params.id, shopId: req.user.shopId });

    if (!item) {
      return res.status(404).json({ message: 'Inventory item not found' });
    }

    const { itemName, itemType, quantity, unit, minQuantity, purchaseAmount, description, costPerUnit } = req.body;

    if (itemName) item.itemName = itemName;
    if (itemType) item.itemType = itemType;
    if (quantity !== undefined) item.quantity = Number(quantity);
    if (unit) item.unit = unit;
    if (minQuantity !== undefined) item.minQuantity = Number(minQuantity);
    if (costPerUnit !== undefined) item.costPerUnit = Number(costPerUnit);

    const pAmount = purchaseAmount !== undefined ? Number(purchaseAmount) : 0;
    if (pAmount > 0) {
      item.lastPurchaseAmount = pAmount;
      item.purchaseHistory.push({ amount: pAmount, date: new Date() });
    }

    const updatedItem = await item.save();

    if (pAmount > 0) {
      await LedgerEntry.create({
        shopId: req.user.shopId,
        amount: pAmount,
        category: 'Inventory',
        description: description || `Restocked ${updatedItem.itemName}`,
        referenceId: updatedItem._id,
      });
    }

    res.json(updatedItem);
  } catch (error) {
    console.error('Update inventory item error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete an inventory item
// @route   DELETE /api/inventory/:id
// @access  Private
export const deleteInventoryItem = async (req, res) => {
  try {
    const item = await Inventory.findOne({ _id: req.params.id, shopId: req.user.shopId });

    if (!item) {
      return res.status(404).json({ message: 'Inventory item not found' });
    }

    await Inventory.deleteOne({ _id: item._id });
    res.json({ message: 'Inventory item deleted successfully' });
  } catch (error) {
    console.error('Delete inventory item error:', error);
    res.status(500).json({ message: error.message });
  }
};
