import Karigar from '../models/Karigar.js';
import Order from '../models/Order.js';
import {
  accrueKarigarWage,
  recordKarigarPayout,
  getKarigarWageSummary,
} from '../services/karigarWageService.js';

// @desc    Create a new Karigar (artisan)
// @route   POST /api/karigars
// @access  Private
export const createKarigar = async (req, res) => {
  try {
    const { name, phone, specialization, status } = req.body;

    if (!name || !phone) {
      return res.status(400).json({ message: 'Karigar name and phone number are required' });
    }

    const karigar = await Karigar.create({
      shopId: req.user.shopId,
      name,
      phone,
      specialization: specialization || 'General',
      status: status || 'Active',
    });

    res.status(201).json(karigar);
  } catch (error) {
    console.error('Create karigar error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all Karigars for a shop
// @route   GET /api/karigars
// @access  Private
export const getKarigars = async (req, res) => {
  try {
    const search = req.query.search || '';
    const filter = { shopId: req.user.shopId };

    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
        { specialization: { $regex: search, $options: 'i' } },
      ];
    }

    const karigars = await Karigar.find(filter).sort({ name: 1 });
    res.json(karigars);
  } catch (error) {
    console.error('Get karigars error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get details of a single Karigar
// @route   GET /api/karigars/:id
// @access  Private
export const getKarigarById = async (req, res) => {
  try {
    const karigar = await Karigar.findOne({ _id: req.params.id, shopId: req.user.shopId });

    if (!karigar) {
      return res.status(404).json({ message: 'Karigar not found' });
    }

    // Fetch orders assigned to this Karigar
    const orders = await Order.find({ assignedKarigar: karigar._id, shopId: req.user.shopId })
      .sort({ deliveryDate: 1 });

    const activeOrders = [];
    const completedOrders = [];
    let totalValue = 0;
    let completedValue = 0;
    let onTimeCompleted = 0;

    for (let o of orders) {
      if (['Ready', 'Delivered'].includes(o.status)) {
        completedOrders.push(o);
        completedValue += o.price || 0;
        
        // On-time check: was it completed before or on the deliveryDate?
        if (o.updatedAt <= o.deliveryDate) {
          onTimeCompleted++;
        }
      } else {
        activeOrders.push(o);
      }
      totalValue += o.price || 0;
    }

    const totalOrders = orders.length;
    const completedCount = completedOrders.length;
    const activeCount = activeOrders.length;
    const onTimeRate = completedCount > 0 
      ? Math.round((onTimeCompleted / completedCount) * 100) 
      : 100; // Default to 100% if no completed orders

    res.json({
      karigar,
      stats: {
        totalOrders,
        activeCount,
        completedCount,
        completedValue,
        onTimeRate
      },
      activeOrders,
      completedOrders: completedOrders.slice(0, 10)
    });
  } catch (error) {
    console.error('Get karigar by ID error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update Karigar details
// @route   PUT /api/karigars/:id
// @access  Private
export const updateKarigar = async (req, res) => {
  try {
    const karigar = await Karigar.findOne({ _id: req.params.id, shopId: req.user.shopId });

    if (!karigar) {
      return res.status(404).json({ message: 'Karigar not found' });
    }

    const { name, phone, specialization, status } = req.body;

    if (name) karigar.name = name;
    if (phone) karigar.phone = phone;
    if (specialization) karigar.specialization = specialization;
    if (status) karigar.status = status;

    const updatedKarigar = await karigar.save();
    res.json(updatedKarigar);
  } catch (error) {
    console.error('Update karigar error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete a Karigar record
// @route   DELETE /api/karigars/:id
// @access  Private
export const deleteKarigar = async (req, res) => {
  try {
    const karigar = await Karigar.findOne({ _id: req.params.id, shopId: req.user.shopId });

    if (!karigar) {
      return res.status(404).json({ message: 'Karigar not found' });
    }

    // Unassign this Karigar from any associated orders to prevent broken ID references
    await Order.updateMany(
      { assignedKarigar: karigar._id, shopId: req.user.shopId },
      { $set: { assignedKarigar: null } }
    );

    await Karigar.deleteOne({ _id: karigar._id });
    res.json({ message: 'Karigar deleted successfully and unassigned from active jobs' });
  } catch (error) {
    console.error('Delete karigar error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get piece-rate wage summary and transaction history for a Karigar (Phase 7, 11.7)
// @route   GET /api/karigars/:id/wages
// @access  Private (Owner, Manager, or Assigned Karigar)
export const getKarigarWages = async (req, res) => {
  try {
    const karigarId = req.params.id;
    const userRole = (req.user.role || 'staff').toLowerCase();
    const isKarigar = userRole === 'karigar' || userRole === 'tailor';

    // Karigar can only see their own wages
    if (isKarigar) {
      const myKarigarId = String(req.user.karigarId || req.user._id);
      if (String(karigarId) !== myKarigarId) {
        return res.status(403).json({ message: 'Forbidden: You can only view your own wages.' });
      }
    }

    const summary = await getKarigarWageSummary({
      shopId: req.user.shopId,
      karigarId,
    });

    res.json(summary);
  } catch (error) {
    console.error('Get karigar wages error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Accrue piece-rate wage for a completed order
// @route   POST /api/karigars/:id/wages/accrue
// @access  Private (Owner, Manager)
export const accrueWage = async (req, res) => {
  try {
    const { orderId, garmentName, customRate } = req.body;
    if (!orderId) return res.status(400).json({ message: 'orderId is required' });

    const result = await accrueKarigarWage({
      shopId: req.user.shopId,
      karigarId: req.params.id,
      orderId,
      garmentName,
      customRate,
      recordedBy: req.user.name || 'Owner',
    });

    res.status(result.accrued ? 201 : 200).json(result);
  } catch (error) {
    console.error('Accrue wage error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Record wage payout settlement to Karigar
// @route   POST /api/karigars/:id/wages/payout
// @access  Private (Owner, Manager)
export const recordPayout = async (req, res) => {
  try {
    const { amount, paymentMode, referenceNote } = req.body;
    if (!amount) return res.status(400).json({ message: 'amount is required' });

    const entry = await recordKarigarPayout({
      shopId: req.user.shopId,
      karigarId: req.params.id,
      amount,
      paymentMode,
      referenceNote,
      recordedBy: req.user.name || 'Owner',
    });

    res.status(201).json({
      message: 'Payout recorded successfully',
      entry,
    });
  } catch (error) {
    console.error('Record payout error:', error);
    res.status(500).json({ message: error.message });
  }
};
