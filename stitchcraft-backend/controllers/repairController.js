import Repair from '../models/Repair.js';

export const createRepair = async (req, res) => {
  try {
    const { customerName, customerPhone, items, totalCost, notes, status, deliveryDate } = req.body;
    const idempotencyKey = req.headers['idempotency-key'] || req.body.idempotencyKey;
    const shopId = req.user.shopId;

    if (idempotencyKey) {
      const existing = await Repair.findOne({ shopId, idempotencyKey });
      if (existing) {
        return res.status(200).json(existing);
      }
    }

    const newRepair = await Repair.create({
      shopId,
      customerName: customerName || 'Walk-in Customer',
      customerPhone: customerPhone || '',
      items: items || [],
      totalCost: Number(totalCost) || 0,
      notes: notes || '',
      status: status || 'Pending',
      deliveryDate: deliveryDate || new Date().toISOString(),
      idempotencyKey: idempotencyKey || null,
      createdAt: new Date().toISOString(),
    });

    res.status(201).json(newRepair);
  } catch (error) {
    console.error('Create repair error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getRepairs = async (req, res) => {
  try {
    const repairs = await Repair.find({ shopId: req.user.shopId, isDeleted: { $ne: true } })
      .sort({ createdAt: -1 });
    res.json(repairs);
  } catch (error) {
    console.error('Get repairs error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const updateRepair = async (req, res) => {
  try {
    const { id } = req.params;
    const repair = await Repair.findOne({ _id: id, shopId: req.user.shopId });
    if (!repair) {
      return res.status(404).json({ message: 'Repair ticket not found' });
    }

    const { status, notes, totalCost, items } = req.body;
    if (status) repair.status = status;
    if (notes !== undefined) repair.notes = notes;
    if (totalCost !== undefined) repair.totalCost = Number(totalCost) || 0;
    if (items) repair.items = items;
    repair.updatedAt = new Date().toISOString();

    await repair.save();
    res.json(repair);
  } catch (error) {
    console.error('Update repair error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const deleteRepair = async (req, res) => {
  try {
    const { id } = req.params;
    const repair = await Repair.findOne({ _id: id, shopId: req.user.shopId });
    if (!repair) {
      return res.status(404).json({ message: 'Repair ticket not found' });
    }

    repair.isDeleted = true;
    repair.deletedAt = new Date().toISOString();
    await repair.save();

    res.json({ success: true, message: 'Repair ticket deleted successfully' });
  } catch (error) {
    console.error('Delete repair error:', error);
    res.status(500).json({ message: error.message });
  }
};

